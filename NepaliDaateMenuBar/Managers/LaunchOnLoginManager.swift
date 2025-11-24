//
//  LaunchOnLoginManager.swift
//  NepaliDaateMenuBar
//
//  Manages launch on login functionality
//

import Foundation
import Combine
import ServiceManagement
import AppKit

class LaunchOnLoginManager: ObservableObject {
    static let shared = LaunchOnLoginManager()
    
    @Published var isEnabled: Bool {
        didSet {
            // Save preference for user intent
            UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaultsKeys.launchOnLogin)
            // Attempt to register/unregister with system
            updateLoginItemStatus(enabled: isEnabled)
        }
    }
    
    private var timer: Timer?
    
    private init() {
        // Check actual system state
        self.isEnabled = Self.checkSystemLoginItemStatus()
        
        // Periodically check system state in case user changes it in System Settings
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }
    
    func refreshStatus() {
        // Also call the static method here
        let actualStatus = Self.checkSystemLoginItemStatus()
        if actualStatus != isEnabled {
            DispatchQueue.main.async {
                self.isEnabled = actualStatus
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    
    private static func checkSystemLoginItemStatus() -> Bool {
        if #available(macOS 13.0, *) {
            // Use SMAppService for macOS 13+
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, check if app is in login items
            // This is a fallback - the checkbox serves as user preference
            return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.launchOnLogin)
        }
    }
    
    private func updateLoginItemStatus(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    // Register app to launch on login
                    try SMAppService.mainApp.register()
                } else {
                    // Unregister app from launch on login
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch on login: \(error.localizedDescription)")
            }
        }
        // For older macOS, user needs to manually add via System Settings
    }
    
    func openLoginItemsSettings() {
        // Open System Settings to Login Items
        if #available(macOS 13.0, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // For older macOS
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.users?Login_Items") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

