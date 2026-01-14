//
//  NepaliDaateMenuBarApp.swift
//  NepaliDaateMenuBar
//
//  Main application entry point
//

import SwiftUI

@main
struct NepaliDaateMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updateManager = UpdateManager.shared
    
    var body: some Scene {
        // Empty Settings scene to prevent scene system conflicts
        // The app uses manual window management via AppDelegate
        Settings {
            EmptyView()
        }
        .commands {
            // Remove default menu items that might conflict
            CommandGroup(replacing: .appSettings) {}
            
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates()
                }
            }
        }
    }
}

