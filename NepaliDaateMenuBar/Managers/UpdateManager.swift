import SwiftUI
import Combine
#if SPARKLE
import Sparkle
#endif

class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
#if SPARKLE
    private var updaterController: SPUStandardUpdaterController?
#endif
    
    @Published var isAppStoreCheckEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAppStoreCheckEnabled, forKey: "AppStoreUpdateCheckEnabled")
            TelemetryManager.shared.track("settings.auto_update.changed", with: ["enabled": "\(isAppStoreCheckEnabled)", "type": "appstore"])
        }
    }
    
    override init() {
        self.isAppStoreCheckEnabled = UserDefaults.standard.object(forKey: "AppStoreUpdateCheckEnabled") as? Bool ?? true
        super.init()
        
#if SPARKLE
        // Initialize Sparkle
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
#endif
        
        // Check for updates on launch if appropriate
        checkForUpdatesOnLaunch()
    }
    
    private func checkForUpdatesOnLaunch() {
#if SPARKLE
        // Sparkle handles its own automatic checking based on user settings
#else
        if isAppStoreCheckEnabled {
            checkForAppStoreUpdates(silently: true)
        }
#endif
    }
    
    func checkForUpdates() {
#if SPARKLE
        updaterController?.checkForUpdates(nil)
#else
        checkForAppStoreUpdates(silently: false)
#endif
    }
    
    // MARK: - App Store Update Logic
    
    private func checkForAppStoreUpdates(silently: Bool) {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=calendar.nepali.app") else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let versionString = firstResult["version"] as? String,
                   let trackViewUrl = firstResult["trackViewUrl"] as? String {
                    
                    if isNewerVersion(onlineVersion: versionString) {
                        DispatchQueue.main.async {
                            self.showUpdateAlert(version: versionString, url: trackViewUrl)
                        }
                    } else if !silently {
                        DispatchQueue.main.async {
                            self.showNoUpdateAlert()
                        }
                    }
                }
            } catch {
                print("Error checking App Store: \(error)")
            }
        }
    }
    
    private func isNewerVersion(onlineVersion: String) -> Bool {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        
        return onlineVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
    
    private func showUpdateAlert(version: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "New Version Available"
        alert.informativeText = "Version \(version) is available on the App Store."
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let updateUrl = URL(string: url) {
                NSWorkspace.shared.open(updateUrl)
            }
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "You have the latest version of the app."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
#if SPARKLE
    var automaticallyChecksForUpdates: Bool {
        get {
            return updaterController?.updater.automaticallyChecksForUpdates ?? false
        }
        set {
            updaterController?.updater.automaticallyChecksForUpdates = newValue
            TelemetryManager.shared.track("settings.auto_update.changed", with: ["enabled": "\(newValue)", "type": "sparkle"])
        }
    }
#endif
}
