//
//  CalendarEventManager.swift
//  NepaliDaateMenuBar
//
//  Manages system calendar events using EventKit
//

import Foundation
import EventKit
import Combine

class CalendarEventManager: ObservableObject {
    static let shared = CalendarEventManager()
    
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var events: [EKEvent] = []
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    private var hasFullAccess: Bool {
        if #available(macOS 14.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            return authorizationStatus == .authorized
        }
    }
    
    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                // Request read-only access for calendar events
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return granted
            } catch {
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return false
            }
        } else {
            do {
                // Request read access to events
                let status = try await eventStore.requestAccess(to: .event)
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return status
            } catch {
                await MainActor.run {
                    checkAuthorizationStatus()
                }
                return false
            }
        }
    }
    
    func fetchEvents(for date: Date) async -> [EKEvent] {
        guard hasFullAccess else {
            return []
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        await MainActor.run {
            self.events = fetchedEvents
        }
        
        return fetchedEvents
    }
    
    func fetchEvents(for startDate: Date, endDate: Date) async -> [EKEvent] {
        guard hasFullAccess else {
            return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        await MainActor.run {
            self.events = fetchedEvents
        }
        
        return fetchedEvents
    }
    
    func getEvents(for nepaliDate: NepaliDate) async -> [EKEvent] {
        // Convert Nepali date to Gregorian date range
        guard let gregorianDate = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: nepaliDate) else {
            return []
        }
        
        return await fetchEvents(for: gregorianDate)
    }
    
    func getEvents(for startNepaliDate: NepaliDate, endNepaliDate: NepaliDate) async -> [EKEvent] {
        guard let startGregorian = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: startNepaliDate),
              let endGregorian = NepaliDateConverter.convertNepaliToGregorian(nepaliDate: endNepaliDate) else {
            return []
        }
        
        // Add one day to end date to include the full day
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 1, to: endGregorian) ?? endGregorian
        
        return await fetchEvents(for: startGregorian, endDate: endDate)
    }
}

