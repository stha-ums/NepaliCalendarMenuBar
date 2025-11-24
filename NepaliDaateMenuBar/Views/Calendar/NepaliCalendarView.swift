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
                .padding(.vertical, 10)
            
            Divider()
            
            // View mode content
            if viewMode == .month {
                monthGridView
                    .padding(8)
            } else {
                // Use the new Agenda View
                agendaView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            selectedDate = currentNepaliDate
            loadEvents()
        }
        .onChange(of: currentDate) { _, _ in loadEvents() }
        .onChange(of: viewMode) { _, _ in loadEvents() }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if let nepaliDate = displayedNepaliDate {
                Text(nepaliDate.formattedDate)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 8) {
                // View mode toggle
                Picker("", selection: $viewMode) {
                    Text("Month").tag(CalendarViewMode.month)
                    // Renamed to Agenda
                    Text("Agenda").tag(CalendarViewMode.agenda)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)
                
                Spacer()
                
                if viewMode == .month {
                    Button(action: previousPeriod) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
                
                Button("Today") {
                    currentDate = Date()
                    selectedDate = currentNepaliDate
                    
                    // Scroll to top in Agenda view
                    if viewMode == .agenda {
                        withAnimation {
                            // Scroll to the top anchor
                            scrollProxy?.scrollTo(agendaScrollAnchor, anchor: .top)
                        }
                    }
                }
                .font(.system(size: 10))
                .buttonStyle(.bordered)
                .controlSize(.mini)
                
                if viewMode == .month {
                    Button(action: nextPeriod) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Month Grid View
    
    private var monthGridView: some View {
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
                            onSelect: {
                                selectedDate = dayInfo.nepaliDate
                            }
                        )
                    }
                }
                
                // Selected day events
                if let selected = selectedDate {
                    selectedDayEventsView(for: selected)
                }
            }
        }
    }
    
    // MARK: - Agenda View (Replaces Schedule)
    
    private var agendaView: some View {
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
                                    events: dayEvents
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
    
    // MARK: - Selected Day Events (for Month View)
    
    @ViewBuilder
    private func selectedDayEventsView(for nepaliDate: NepaliDate) -> some View {
        let dayEvents = getEvents(for: nepaliDate)
        
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            
            HStack(alignment: .center, spacing: 6) {
                Text(nepaliDate.formattedDate)
                    .font(.subheadline.weight(.semibold))
                
                if let gregorianDate = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: nepaliDate) {
                    Text("(\(formatGregorianDate(gregorianDate)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !dayEvents.isEmpty {
                    Text("\(dayEvents.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor))
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            if dayEvents.isEmpty {
                Text("No events")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 1. Cleaner loop (assuming Event is Identifiable)
                        ForEach(dayEvents, id: \.eventIdentifier) { event in
                                    CompactEventRow(event: event)
                                }
                       
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensures content stays left
                }
                
                
            }
        }
    }
    
    // MARK: - Helpers
    
    private func previousPeriod() {
        let calendar = Calendar.current
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }
        // No action needed for Agenda view
    }
    
    private func nextPeriod() {
        let calendar = Calendar.current
        if viewMode == .month {
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        // No action needed for Agenda view
    }
    
    
    private func generateMonthGrid(for nepaliDate: NepaliDate) -> [CalendarDayInfo] {
        var grid: [CalendarDayInfo] = []
        
        guard let yearData = NepaliDateConverter.calendarData[nepaliDate.year] else {
            return grid
        }
        
        let daysInMonth = yearData.daysInMonths[nepaliDate.month - 1]
        
        guard let firstDayGregorian = NepaliDateConverter.convertNepaliToGregorian(
            nepaliDate: NepaliDate(year: nepaliDate.year, month: nepaliDate.month, day: 1)
        ) else {
            return grid
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: firstDayGregorian)
        let offset = (weekday - 1) % 7
        
        for _ in 0..<offset {
            grid.append(CalendarDayInfo(nepaliDate: nil, gregorianDate: nil, isCurrentMonth: false))
        }
        
        for day in 1...daysInMonth {
            let dayNepaliDate = NepaliDate(year: nepaliDate.year, month: nepaliDate.month, day: day)
            if let gregorianDate = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: dayNepaliDate) {
                grid.append(CalendarDayInfo(nepaliDate: dayNepaliDate, gregorianDate: gregorianDate, isCurrentMonth: true))
            }
        }
        
        while grid.count < Constants.Grid.totalCells {
            grid.append(CalendarDayInfo(nepaliDate: nil, gregorianDate: nil, isCurrentMonth: false))
        }
        
        return grid
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
                // Month view: load events for the visible month
                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
                endDate = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: startDate) ?? currentDate
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
}
