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
            } catch {
                NSLog("Reynard: failed to clear Gecko browsing data: %@", "\\(error)")
            }
        }
    }
}
