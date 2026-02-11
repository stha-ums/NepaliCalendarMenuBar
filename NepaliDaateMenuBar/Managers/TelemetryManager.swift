//
//  TelemetryManager.swift
//  NepaliDaateMenuBar
//
//  Manages TelemetryDeck initialization and event tracking
//

import Foundation
import TelemetryDeck

class TelemetryManager {
    static let shared = TelemetryManager()
    private var isInitialized = false
    
    private init() {}
    
    func setup() {
        #if DEBUG
        if let infoDict = Bundle.main.infoDictionary {
            print("📦 TelemetryDeck: Available Info.plist keys: \(infoDict.keys.sorted().joined(separator: ", "))")
        }
        #endif

        let rawAppID = Bundle.main.object(forInfoDictionaryKey: "TelemetryAppID") as? String
        
        #if DEBUG
        print("🔍 TelemetryDeck: Raw App ID from Info.plist: '\(rawAppID ?? "nil")'")
        if rawAppID == nil {
            if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) {
                print("📂 TelemetryDeck: Content of Info.plist at \(path): \(dict)")
            } else {
                print("❌ TelemetryDeck: Could not find or read Info.plist from bundle")
            }
        }
        #endif

        guard let appID = rawAppID,
              !appID.isEmpty,
              appID != "$(TELEMETRY_APP_ID)" else {
            print("⚠️ TelemetryDeck: App ID not found or not configured (TELEMETRY_APP_ID build setting missing). Skipping initialization.")
            return
        }
        
        let configuration = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: configuration)
        isInitialized = true
        
        #if DEBUG
        print("✅ TelemetryDeck: Initialized")
        #endif
        
        #if SPARKLE
        let versionType = "github"
        let autoUpdate = UpdateManager.shared.automaticallyChecksForUpdates
        #else
        let versionType = "appstore"
        let autoUpdate = UpdateManager.shared.isAppStoreCheckEnabled
        #endif
        
        track("app.launched", with: [
            "version_type": versionType,
            "auto_update_enabled": "\(autoUpdate)"
        ])
    }
    
    func track(_ eventName: String, with properties: [String: String]? = nil) {
        guard isInitialized else {
            #if DEBUG
            print("⏸️ TelemetryDeck: Skipping signal '\(eventName)' - SDK not initialized.")
            #endif
            return
        }
        
        TelemetryDeck.signal(eventName, parameters: properties ?? [:])
        
        #if DEBUG
        print("📊 TelemetryDeck: Signal sent -> \(eventName) \(properties ?? [:])")
        #endif
    }
}
