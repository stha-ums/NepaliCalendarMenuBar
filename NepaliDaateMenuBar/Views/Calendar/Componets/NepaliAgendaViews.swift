//
//  NepaliAgendaViews.swift
//  NepaliDaateMenuBar
//
//  Subviews for the Agenda View
//

import SwiftUI
import EventKit

// MARK: - Agenda Day Section (Google Calendar style)

struct AgendaDaySection: View {
    let nepaliDate: NepaliDate
    let gregorianDate: Date
    let isToday: Bool
    let events: [EKEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header - sticky
            HStack(spacing: 10) {
                // Nepali day circle
                VStack(spacing: 2) {
                    Text(nepaliDayOfWeekShort)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isToday ? .white : .secondary)
                    
                    Text(toNepaliNumerals(nepaliDate.day))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isToday ? .white : .primary)
                }
                .frame(width: 42)
                .padding(.vertical, 6)
                .background(isToday ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                VStack(alignment: .leading, spacing: 3) {
                    // Nepali date (primary)
                    Text(nepaliDate.monthName)
                        .font(.system(size: 12, weight: .semibold))
                    
                    // Gregorian date (small, secondary)
                    Text(gregorianDateString)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    if events.count > 0 {
                        Text("\(events.count) event\(events.count > 1 ? "s" : "")")
                            .font(.system(size: 8))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Events
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(sortedEvents.enumerated()), id: \.offset) { _, event in
                        // Use the renamed struct
                        AgendaEventRow(event: event)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)
                .padding(.bottom, 12)
            }
        }
    }
    
    private var nepaliDayOfWeekShort: String {
        let language = LanguageSettings.shared.language
        let weekday = Calendar.current.component(.weekday, from: gregorianDate)
        let days = language == .nepali ? Constants.Weekdays.nepaliShort : Constants.Weekdays.english
        return days[weekday - 1]
    }
    
    private var gregorianDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: gregorianDate)
    }
    
    private func toNepaliNumerals(_ number: Int) -> String {
        let numeralMap: [Character: String] = [
            "0": "०", "1": "१", "2": "२", "3": "३", "4": "४",
            "5": "५", "6": "६", "7": "७", "8": "८", "9": "९"
        ]
        
        return String(number).map { numeralMap[$0] ?? String($0) }.joined()
    }
    
    private var sortedEvents: [EKEvent] {
        events.sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Agenda Event Row (Google Calendar style)

struct AgendaEventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 10) {
            // Time
            if let startDate = event.startDate {
                Text(startDate, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
            }
            
            // Event card
            HStack(spacing: 8) {
                // Color indicator
                Rectangle()
                    .fill(eventColor(event))
                    .frame(width: 3)
                
                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    
                    if let startDate = event.startDate, let endDate = event.endDate {
                        Text("\(startDate, style: .time) - \(endDate, style: .time)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(eventColor(event).opacity(0.08))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(eventColor(event).opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func eventColor(_ event: EKEvent) -> Color {
        if let calendar = event.calendar {
            return Color(calendar.color)
        }
        return Color.blue
    }
}
