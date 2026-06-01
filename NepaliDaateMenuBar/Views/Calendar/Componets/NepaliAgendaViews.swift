//
//  NepaliAgendaViews.swift
//  NepaliDaateMenuBar
//
//  Subviews for the Agenda View
//

import SwiftUI
import EventKit

// MARK: - Agenda Empty State

struct AgendaEmptyState: View {
    let authorizationStatus: EKAuthorizationStatus
    let onGrant: () -> Void

    private var isNotDetermined: Bool { authorizationStatus == .notDetermined }
    private var isDenied: Bool { authorizationStatus == .denied || authorizationStatus == .restricted }

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            // Text
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action
            if isNotDetermined {
                Button(action: onGrant) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Connect Calendar")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else if isDenied {
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Open System Settings")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(.orange)
            } else {
                // Access granted but no events — offer Internet Accounts
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add Calendar Account")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
    }

    private var iconName: String {
        if isNotDetermined { return "calendar.badge.plus" }
        if isDenied        { return "calendar.badge.exclamationmark" }
        return "calendar.badge.checkmark"
    }

    private var iconColor: Color {
        if isNotDetermined { return .accentColor }
        if isDenied        { return .orange }
        return .secondary
    }

    private var title: String {
        if isNotDetermined { return "Connect Your Calendar" }
        if isDenied        { return "Calendar Access Denied" }
        return "No Upcoming Events"
    }

    private var subtitle: String {
        if isNotDetermined { return "See your events alongside Nepali dates and tithi." }
        if isDenied        { return "Enable calendar access in System Settings → Privacy & Security → Calendars." }
        return "Events you create in the next 60 days will appear here."
    }
}

// MARK: - Agenda Day Section (Google Calendar style)

struct AgendaDaySection: View {
    let nepaliDate: NepaliDate
    let gregorianDate: Date
    let isToday: Bool
    let events: [EKEvent]
    let tithiName: String?
    let onEventSelect: (EKEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header - sticky
            HStack(spacing: 10) {
                // Nepali day circle
                VStack(spacing: 2) {
                    Text(nepaliDayOfWeekShort)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isToday ? .white : .secondary)
                    
                    Text(toNepaliNumerals(nepaliDate.day))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isToday ? .white : .primary)
                }
                .frame(width: 44, height: 44)
                .background(
                    isToday ? 
                    AnyView(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.accentColor)) : 
                    AnyView(Color.clear)
                )
                .overlay(
                    !isToday ? 
                    AnyView(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1)) : 
                    AnyView(Color.clear)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        // Nepali date (primary)
                        Text(nepaliDate.fullFormattedDate(with: gregorianDate))
                            .font(.system(size: 14, weight: .bold))
                        
                        if let tithi = tithiName {
                            Text(tithi)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // Gregorian date (small, secondary)
                    Text(gregorianFullDateString)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Events
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(sortedEvents.enumerated()), id: \.offset) { index, event in
                        AgendaEventRow(event: event) {
                            onEventSelect(event)
                        }
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
    
    private var gregorianFullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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
        // Deduplicate events by their ID to prevent ForEach crashes
        var seen = Set<String>()
        let uniqueEvents = events.filter { event in
            let id = event.id
            if seen.contains(id) {
                return false
            }
            seen.insert(id)
            return true
        }
        return uniqueEvents.sorted { $0.startDate < $1.startDate }
    }
}

// MARK: - Agenda Event Row (Google Calendar style)

struct AgendaEventRow: View {
    let event: EKEvent
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Time
            if let startDate = event.startDate {
                Text(startDate, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .leading)
            }
            
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    // Color indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(event.swiftUIColor)
                        .frame(width: 4)
                    
                    // Event info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(2)
                        
                        if let startDate = event.startDate, let endDate = event.endDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9))
                                Text("\(startDate, style: .time) - \(endDate, style: .time)")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    event.swiftUIColor
                        .opacity(isHovered ? 0.2 : 0.1)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(event.swiftUIColor.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
}
