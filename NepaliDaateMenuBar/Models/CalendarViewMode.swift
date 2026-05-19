//
//  CalendarViewMode.swift
//  NepaliDaateMenuBar
//
//  Calendar view mode enumeration
//

import Foundation

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case agenda = "Agenda"
}

extension Notification.Name {
    static let popoverDidClose = Notification.Name("NepaliDateMenuBar.popoverDidClose")
}

