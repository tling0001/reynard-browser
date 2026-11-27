//
//  PrivacyResetCoordinator.swift
//  Reynard
//
//  This fork intentionally starts a fresh browsing session on every launch
//  and after a device-lock event. Ordinary app/window switching is preserved.
//

import GeckoView
import UIKit

@MainActor
enum PrivacyResetCoordinator {
    private static let deviceLockPendingKey = "PrivacyResetCoordinator.deviceLockPending"
    private static var isResetting = false

    /// Called when iOS reports that protected data is about to become unavailable.
    /// Persist the marker because the app may be suspended before it can act.
    static func noteDeviceLock() {
        UserDefaults.standard.set(true, forKey: deviceLockPendingKey)
    }

    /// Consume the lock marker on return. Ordinary foreground transitions do
    /// nothing unless iOS previously reported a device-lock/protected-data event.
    @discardableResult
    static func resetIfDeviceWasLocked() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: deviceLockPendingKey) else {
            return false
        }

        // Clear first so multiple scenes becoming active cannot repeat the reset.
        defaults.removeObject(forKey: deviceLockPendingKey)
        reset(reason: "device locked while app was inactive")
        return true
    }

    static func reset(reason: String) {
        guard !isResetting else { return }
        isResetting = true

        NSLog("Reynard: performing mandatory privacy reset (%@)", reason)

        // Remove live tabs in every connected window and replace them with a
        // clean home tab. This also persists the empty tab state for relaunch.
        BrowserWindowManager.shared.removeAllTabs()

        // Clear locally persisted browsing activity and per-site state while
        // preserving user configuration such as bookmarks and add-ons.
        HistoryStore.shared.clearVisits(since: nil)
        TabManagementStore.shared.clearRecentlyClosedTabs()
        SiteSettingsStore.shared.clearAllSettings()
        SiteSettingsUtils.resetStoredSitePermissions()
        FaviconStore.shared.clearCache()
        DownloadStore.shared.clearCompletedDownloadFiles()

        Task { @MainActor in
            defer { isResetting = false }
            do {
                let flags = GeckoStorageClearFlags.cookies
                    | GeckoStorageClearFlags.networkCache
                    | GeckoStorageClearFlags.imageCache
                    | GeckoStorageClearFlags.history
                    | GeckoStorageClearFlags.domStorages
                    | GeckoStorageClearFlags.authSessions
                try await GeckoStorageController.clearData(flags: flags)
                await GeckoStorageController.clearTranslationModelCache()
                showResetToast(message: "Browsing session reset")
            } catch {
                NSLog("Reynard: failed to clear Gecko browsing data: %@", "\\(error)")
                showResetToast(message: "Browsing session reset (some data could not be cleared)")
            }
        }
    }

    private static func showResetToast(message: String) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let toast = UIView()
        toast.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.92)
        toast.layer.cornerRadius = 14
        toast.layer.masksToBounds = true
        toast.alpha = 0
        toast.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = message
        label.textColor = .systemBackground
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(label)
        window.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 24),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -24),
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16)
        ])

        UIView.animate(withDuration: 0.25) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            UIView.animate(withDuration: 0.25, animations: { toast.alpha = 0 }) {
                toast.removeFromSuperview()
            }
        }
    }
}
