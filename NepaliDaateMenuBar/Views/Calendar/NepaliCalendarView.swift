//
//  NepaliCalendarView.swift
//  NepaliDaateMenuBar
//
//  Minimal Nepali calendar view with events
//

import SwiftUI
import EventKit

struct NepaliCalendarView: View {
    @StateObject private var eventManager: CalendarEventManager = CalendarEventManager.shared
    @State private var currentDate = Date()
    @State private var selectedDate: NepaliDate?
    @State private var events: [EKEvent] = []
    @State private var viewMode: CalendarViewMode = .month
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var selectedEvent: EKEvent?
    @State private var pendingEvent: EKEvent? // For robust swapping
    
    // Removed unused state:
    // @State private var scheduleStartOffset: Int = Constants.Schedule.initialPastDays
    // @State private var scheduleEndOffset: Int = Constants.Schedule.initialFutureDays
    // @State private var isLoadingMore = false
    
    private let agendaLookAheadDays = 60
    private let agendaScrollAnchor = "TODAY_ANCHOR"
    
    private var displayedNepaliDate: NepaliDate? {
        NepaliDateConverter.convertToNepali(gregorianDate: currentDate)
    }
    
    private var currentNepaliDate: NepaliDate? {
        NepaliDateConverter.getCurrentNepaliDate()
    }
    
    private var weekdayHeaders: [String] {
        LanguageSettings.shared.language == .nepali ?
            Constants.Weekdays.nepali : Constants.Weekdays.english
    }
    
    // MARK: - Agenda Computed Properties
    
    /// Groups all fetched events by the start of their day.
    private var eventsGroupedByDay: [Date: [EKEvent]] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // 1. Filter for upcoming events only
        let upcomingEvents = self.events.filter { $0.startDate >= startOfToday }
        
        // 2. Group them by their start day
        let grouped = Dictionary(grouping: upcomingEvents) { event in
            return calendar.startOfDay(for: event.startDate)
        }
        
        return grouped
    }
    
    /// Provides the sorted list of days that have events.
    private var sortedEventDays: [Date] {
        eventsGroupedByDay.keys.sorted()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            headerView
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 10)
            
            Divider()
            
            // View mode content
            if viewMode == .month {
                VStack(spacing: 0) {
                    monthGridView(selectedEvent: $selectedEvent)
                        .padding(.bottom, 8)

                    Divider()

                    // Selected date agenda panel
                    SelectedDayAgendaPanel(
                        currentDate: currentDate,
                        selectedDate: selectedDate,
                        events: getEvents(for: selectedDate),
                        onEventSelect: selectEvent
                    )

                    footerView
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            } else {
                // Use the new Agenda View
                agendaView(selectedEvent: $selectedEvent)
            }
            
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .popover(item: $selectedEvent, arrowEdge: .trailing) { event in
            EventDetailPopup(event: event, onClose: {
                selectedEvent = nil
            })
            .onDisappear {
                // If we have a pending event from a swap, trigger it now that
                // the previous popover has fully finished its dismissal
                if let nextEvent = pendingEvent {
                    pendingEvent = nil
                    // Small delay helps ensure SwiftUI's state machine is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.selectedEvent = nextEvent
                    }
                }
            }
            .padding(8) // Add some padding for the popover
        }
        .task {
            if selectedDate == nil {
                selectedDate = currentNepaliDate
            }
            loadEvents()
        }
        .onChange(of: currentDate) { _ in loadEvents() }
        .onChange(of: viewMode) { newValue in 
            loadEvents() 
            TelemetryManager.shared.track("view.mode.changed", with: ["mode": newValue.rawValue])
        }
        .onChange(of: eventManager.authorizationStatus) { _ in
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidClose)) { _ in
            viewMode = .month
            currentDate = Date()
            selectedDate = currentNepaliDate
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month + year (left) | today's full date + tithi (right)
            if let nepaliDate = displayedNepaliDate {
                HStack(alignment: .center) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(nepaliDate.monthName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Text(NumeralConverter.convert(nepaliDate.year, for: LanguageSettings.shared.language))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let today = currentNepaliDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(today.fullFormattedDate(with: Date()))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)

                            if let tithi = NepaliDateConverter.getTithiName(for: Date()) {
                                Text(tithi)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
            }

            // Tabs + navigation
            HStack(spacing: 12) {
                ViewModeSwitcher(selection: $viewMode)

                Spacer()

                HStack(spacing: 10) {
                    if viewMode == .month {
                        HeaderIconButton(icon: "chevron.left", action: previousPeriod)
                    }

                    TodayButton {
                        currentDate = Date()
                        selectedDate = currentNepaliDate

                        TelemetryManager.shared.track("button.today.clicked", with: ["mode": viewMode.rawValue])

                        if viewMode == .agenda {
                            withAnimation {
                                scrollProxy?.scrollTo(agendaScrollAnchor, anchor: .top)
                            }
                        }
                    }

                    if viewMode == .month {
                        HeaderIconButton(icon: "chevron.right", action: nextPeriod)
                    }
                }
            }
        }
    }
    
    // MARK: - Month Grid View
    
    private func monthGridView(selectedEvent: Binding<EKEvent?>) -> some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.bottom, 6)
            
            // Calendar days
            if let nepaliDate = displayedNepaliDate {
                let grid = generateMonthGrid(for: nepaliDate)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Constants.Grid.gridSpacing), count: Constants.Grid.daysPerWeek), spacing: Constants.Grid.gridSpacing) {
                    ForEach(grid, id: \.id) { dayInfo in
                        CompactDayCell(
                            dayInfo: dayInfo,
                            isToday: isToday(dayInfo.nepaliDate),
                            isSelected: isSelected(dayInfo.nepaliDate),
                            events: getEvents(for: dayInfo.nepaliDate),
                            selectedEvent: selectedEvent,
                            onSelect: {
                                selectedDate = dayInfo.nepaliDate
                                if let gDate = dayInfo.gregorianDate {
                                    currentDate = gDate
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Info Chip (Helper)
    
    private struct InfoChip: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 11, weight: .medium))
            }
        }
    }
    
    // MARK: - Agenda View (Replaces Schedule)
    
    private func agendaView(selectedEvent: Binding<EKEvent?>) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Add an anchor for the "Today" button to scroll to
                    Color.clear
                        .frame(width: 0, height: 0)
                        .id(agendaScrollAnchor)
                    
                    if sortedEventDays.isEmpty {
                        Text("No upcoming events")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(sortedEventDays, id: \.self) { day in
                            // Get events and date info for this day
                            if let dayEvents = eventsGroupedByDay[day],
                               let nepaliDate = NepaliDateConverter.convertToNepali(gregorianDate: day) {
                                
                                // Use the renamed AgendaDaySection
                                    AgendaDaySection(
                                        nepaliDate: nepaliDate,
                                        gregorianDate: day,
                                        isToday: Calendar.current.isDateInToday(day),
                                        events: dayEvents,
                                        tithiName: NepaliDateConverter.getTithiName(for: day),
                                        onEventSelect: selectEvent
                                    )
                                .id(day) // Use the Date as the ID
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .onAppear {
                // Store proxy for the "Today" button
                self.scrollProxy = proxy
            }
        }
    }
    
    // Removed: checkAndLoadMore()
    // Removed: loadMorePastEvents()
    // Removed: loadMoreFutureEvents()
    
    // MARK: - Helpers
    
    private func previousPeriod() {
        let calendar = Calendar.current
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
            SentryManager.shared.trackUserAction("previous_month")
        }
        // No action needed for Agenda view
    }
    
    private func nextPeriod() {
        let calendar = Calendar.current
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            SentryManager.shared.trackUserAction("next_month")
        }
        // No action needed for Agenda view
    }
    
    
    private func generateMonthGrid(for nepaliDate: NepaliDate) -> [CalendarDayInfo] {
        return NepaliDateConverter.getMonthCalendarData(year: nepaliDate.year, month: nepaliDate.month)
    }
    
    private func getWeekStartDate() -> Date? {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))
    }
    
    private func generateWeekDays(from startDate: Date) -> [CalendarDayInfo] {
        var weekDays: [CalendarDayInfo] = []
        let calendar = Calendar.current
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                if let nepaliDate = NepaliDateConverter.convertToNepali(gregorianDate: date) {
                    weekDays.append(CalendarDayInfo(nepaliDate: nepaliDate, gregorianDate: date, isCurrentMonth: true))
                }
            }
        }
        
        return weekDays
    }
    
    private func isToday(_ nepaliDate: NepaliDate?) -> Bool {
        guard let date = nepaliDate, let today = currentNepaliDate else { return false }
        return date.year == today.year && date.month == today.month && date.day == today.day
    }
    
    private func isSelected(_ nepaliDate: NepaliDate?) -> Bool {
        guard let date = nepaliDate, let selected = selectedDate else { return false }
        return date.year == selected.year && date.month == selected.month && date.day == selected.day
    }
    
    private func getEvents(for nepaliDate: NepaliDate?) -> [EKEvent] {
        guard let date = nepaliDate else { return [] }
        
        guard let gregorianDate = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: date) else {
            print("⚠️ Could not convert \(date.formattedDate) to Gregorian")
            return []
        }
        
        // Use local calendar for event comparison
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Get components to reconstruct the date in local time
        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)
        guard let localDate = calendar.date(from: components) else { return [] }
        
        let startOfDay = calendar.startOfDay(for: localDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let filtered = events.filter { event in
            guard let eventStart = event.startDate, let eventEnd = event.endDate else { return false }
            // Check if event overlaps with this day
            return eventStart < endOfDay && eventEnd > startOfDay
        }
        
        return filtered
    }
    
    private func loadEvents() {
        Task {
            let calendar = Calendar.current
            var startDate: Date
            var endDate: Date
            
            if viewMode == .month {
                // Month view: load events for the visible BS month
                // Use currentDate to get the BS month to ensure we always have a reference
                if let nepaliDate = NepaliDateConverter.convertToNepali(gregorianDate: currentDate) {
                    let grid = NepaliDateConverter.getMonthCalendarData(year: nepaliDate.year, month: nepaliDate.month)
                    let visibleDates = grid.compactMap { $0.gregorianDate }
    
                    if let firstDate = visibleDates.first, let lastDate = visibleDates.last {
                        startDate = calendar.startOfDay(for: firstDate)
                        endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastDate)) ?? lastDate
                    } else {
                        startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
                        endDate = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: startDate) ?? currentDate
                    }
                } else {
                    startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
                    endDate = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: startDate) ?? currentDate
                }
            } else {
                // Agenda view: load events from Today up to 60 days in the future
                startDate = calendar.startOfDay(for: Date())
                endDate = calendar.date(byAdding: .day, value: agendaLookAheadDays, to: startDate) ?? Date()
            }
            
            let fetchedEvents = await eventManager.fetchEvents(for: startDate, endDate: endDate)
            
            await MainActor.run {
                self.events = fetchedEvents
            }
        }
    }
    
    private func formatGregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatFullGregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    // MARK: - Event Selection Helper
    
    /// Safely selects an event by managing the dismissal/presentation flow
    private func selectEvent(_ event: EKEvent) {
        // If clicking the same event, toggle it (close)
        if selectedEvent?.eventIdentifier == event.eventIdentifier {
            selectedEvent = nil
            pendingEvent = nil
            SentryManager.shared.trackUserAction("close_event_detail")
        } else if selectedEvent != nil {
            // If another event is already open, we store the new one as pending
            // and close the current one. The swap will happen in onDisappear.
            pendingEvent = event
            selectedEvent = nil
            
            // Track opening the new event
            TelemetryManager.shared.track("calendar.event.opened")
        } else {
            // Normal presentation
            selectedEvent = event
            pendingEvent = nil
            
            // Track opening the event
            TelemetryManager.shared.track("calendar.event.opened")
            SentryManager.shared.trackUserAction("open_event_detail", extra: ["title": event.title ?? "Untitled"])
        }
    }
    
    /// Formats event details for alert display
    private func formatEventDetails(_ event: EKEvent) -> String {
        var details: [String] = []
        
        // Time
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        details.append("⏰ \(start) – \(end)")
        
        // Date
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        details.append("📅 \(formatter.string(from: event.startDate))")
        
        // Location
        if let location = event.location, !location.isEmpty {
            details.append("📍 \(location)")
        }
        
        // Notes (first 100 chars)
        if let notes = event.notes, !notes.isEmpty {
            let cleanNotes = notes.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let truncated = String(cleanNotes.prefix(100))
            details.append("\n\(truncated)\(cleanNotes.count > 100 ? "..." : "")")
        }
        
        return details.joined(separator: "\n")
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack(spacing: 16) {
            FooterButton(title: "Settings", icon: "gearshape") {
                AppDelegate.shared.openSettings()
            }
            
            FooterButton(title: "About", icon: "info.circle") {
                AppDelegate.shared.openAbout()
            }
            
            Spacer()
            
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}

struct FooterButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isHovering ? .accentColor : .secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.accentColor.opacity(isHovering ? 0.15 : 0.05))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
