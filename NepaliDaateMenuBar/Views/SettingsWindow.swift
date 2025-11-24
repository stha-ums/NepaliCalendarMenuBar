//
//  SettingsWindow.swift
//  NepaliDaateMenuBar
//
//  Separate settings window
//

import SwiftUI

struct SettingsWindow: View {
    @ObservedObject var launchOnLoginManager: LaunchOnLoginManager = LaunchOnLoginManager.shared
    @ObservedObject var eventManager: CalendarEventManager = CalendarEventManager.shared
    
    var body: some View {
        SettingsView(launchOnLoginManager: launchOnLoginManager, eventManager: eventManager)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}


