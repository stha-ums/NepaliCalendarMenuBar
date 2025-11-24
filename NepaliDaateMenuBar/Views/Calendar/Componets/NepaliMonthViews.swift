//
//  NepaliMonthViews.swift
//  NepaliDaateMenuBar
//
//  Subviews for the Month View
//

import SwiftUI
import EventKit

// MARK: - Compact Day Cell

struct CompactDayCell: View {
    let dayInfo: CalendarDayInfo
    let isToday: Bool
    let isSelected: Bool
    let events: [EKEvent]
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            if let nepaliDate = dayInfo.nepaliDate {
                Text(toNepaliNumerals(nepaliDate.day))
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(cellBackground)
                
                // Event dots
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(eventColor(event))
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var cellBackground: some View {
        ZStack {
            if isToday {
                Circle()
                    .fill(Color.accentColor)
            } else if isSelected {
                Circle()
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
            }
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if dayInfo.isCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.4)
        }
    }
    
    private func toNepaliNumerals(_ number: Int) -> String {
        NumeralConverter.convert(number, for: LanguageSettings.shared.language)
    }
    
    private func eventColor(_ event: EKEvent) -> Color {
        if let calendar = event.calendar {
            return Color(calendar.color)
        }
        return Color.blue
    }
}

// MARK: - Compact Event Row

struct CompactEventRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(eventColor(event))
                .frame(width: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                
                if let startDate = event.startDate {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                        Text(startDate, style: .time)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(4)
    }
    
    private func eventColor(_ event: EKEvent) -> Color {
        if let calendar = event.calendar {
            return Color(calendar.color)
        }
        return Color.blue
    }
}
