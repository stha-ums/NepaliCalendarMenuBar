//
//  MenuBarPopoverView.swift
//  NepaliDaateMenuBar
//
//  Minimal calendar popover view
//

import SwiftUI
import EventKit

struct MenuBarPopoverView: View {
    @StateObject private var eventManager: CalendarEventManager = CalendarEventManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            NepaliCalendarView()
        }
        .frame(width: Constants.Window.popoverWidth, height: Constants.Window.popoverHeight, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                if eventManager.authorizationStatus == EKAuthorizationStatus.notDetermined {
                    _ = await eventManager.requestAccess()
                }
            }
        }
    }
}
