//
//  PrivacyResetCoordinator.swift
//  Reynard
//
//  This fork intentionally starts a fresh browsing session on every launch
//  and whenever iOS locks the device / makes protected data unavailable.
//

import GeckoView
import UIKit

@MainActor
enum PrivacyResetCoordinator {
    private static var isResetting = false

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
                NSLog("Reynard: failed to clear Gecko browsing data: %@", "\(error)")
            }
        }
    }
}
