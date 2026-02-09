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
    
    // Astronomical info
    var tithiName: String?
    var nakshatraName: String?
    var rashiName: String?
    var sunrise: String?
    var sunset: String?
}

