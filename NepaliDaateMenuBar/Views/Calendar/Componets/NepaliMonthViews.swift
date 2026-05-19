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

// MARK: - Selected Day Agenda Panel

struct SelectedDayAgendaPanel: View {
    let currentDate: Date
    let selectedDate: NepaliDate?
    let events: [EKEvent]
    let onEventSelect: (EKEvent) -> Void

    @State private var carouselIndex: Int = 0

    private var nepaliDate: NepaliDate? {
        guard let sel = selectedDate else { return nil }
        return sel
    }

    private var gregorianDate: Date? {
        guard let sel = selectedDate else { return nil }
        return NepaliDateConverter.convertNepaliToGregorian(nepaliDate: sel) ?? currentDate
    }

    private var sortedEvents: [EKEvent] {
        var seen = Set<String>()
        return events
            .filter { seen.insert($0.eventIdentifier ?? "").inserted }
            .sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Date header row
            if let nepali = nepaliDate, let greg = gregorianDate {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(nepali.fullFormattedDate(with: greg))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)

                            if let tithi = NepaliDateConverter.getTithiName(for: greg) {
                                Text(tithi)
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(5)
                            }
                        }

                        Text(gregFullString(greg))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if sortedEvents.count > 1 {
                        // Carousel navigation arrows + counter
                        HStack(spacing: 6) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    carouselIndex = max(carouselIndex - 1, 0)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(carouselIndex > 0 ? .primary : .secondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(carouselIndex == 0)

                            Text("\(carouselIndex + 1)/\(sortedEvents.count)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .monospacedDigit()

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    carouselIndex = min(carouselIndex + 1, sortedEvents.count - 1)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(carouselIndex < sortedEvents.count - 1 ? .primary : .secondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(carouselIndex == sortedEvents.count - 1)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }

            // Event area
            if sortedEvents.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No events")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            } else {
                let event = sortedEvents[min(carouselIndex, sortedEvents.count - 1)]
                AgendaPanelEventCard(event: event) {
                    onEventSelect(event)
                }
                .id(event.eventIdentifier)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: selectedDate) { _ in
            carouselIndex = 0
        }
    }

    private func gregFullString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: date)
    }
}

// MARK: - Agenda Panel Event Card

struct AgendaPanelEventCard: View {
    let event: EKEvent
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.swiftUIColor)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title ?? "Untitled")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        if event.isAllDay {
                            Text("All day")
                                .font(.system(size: 10))
                        } else if let start = event.startDate, let end = event.endDate {
                            Text("\(start, style: .time) – \(end, style: .time)")
                                .font(.system(size: 10))
                        }
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                event.swiftUIColor.opacity(isHovered ? 0.15 : 0.08)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(event.swiftUIColor.opacity(isHovered ? 0.35 : 0.18), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
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
