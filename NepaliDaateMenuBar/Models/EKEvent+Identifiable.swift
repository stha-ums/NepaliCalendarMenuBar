//
//  EKEvent+Identifiable.swift
//  NepaliDaateMenuBar
//
//  Extension to make EKEvent Identifiable for use in SwiftUI lists and popovers.
//

import EventKit
import SwiftUI

extension EKEvent: Identifiable {
    public var id: String {
        // Combine identifier with dates to ensure uniqueness for recurring events
        let start = startDate?.timeIntervalSince1970 ?? 0
        let end = endDate?.timeIntervalSince1970 ?? 0
        return "\(eventIdentifier)-\(start)-\(end)"
    }
    
    var swiftUIColor: Color {
        if let calendar = self.calendar {
            return Color(calendar.color)
        }
        return .blue
    }
}
