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
    @Binding var selectedEvent: EKEvent?
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            if let nepaliDate = dayInfo.nepaliDate {
                Text(toNepaliNumerals(nepaliDate.day))
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(cellBackground)
                
                // Event dots
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, event in
                            Circle()
                                .fill(event.swiftUIColor)
                                .frame(width: 3, height: 3)
                        }
                    }
                } else {
                    Spacer().frame(height: 3)
                }
            }
        }
        .frame(height: 45)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var cellBackground: some View {
        ZStack {
            if isToday {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            } else if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.accentColor.opacity(0.1)))
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
}

// MARK: - Compact Event Row

struct CompactEventRow: View {
    let event: EKEvent
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(event.swiftUIColor)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(isHovered ? 0.7 : 0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(isHovered ? 0.15 : 0.05), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
