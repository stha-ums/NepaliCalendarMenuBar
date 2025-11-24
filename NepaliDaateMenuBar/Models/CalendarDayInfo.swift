//
//  CalendarDayInfo.swift
//  NepaliDaateMenuBar
//
//  Calendar day information model
//

import Foundation

struct CalendarDayInfo: Identifiable {
    let id = UUID()
    let nepaliDate: NepaliDate?
    let gregorianDate: Date?
    let isCurrentMonth: Bool
}

