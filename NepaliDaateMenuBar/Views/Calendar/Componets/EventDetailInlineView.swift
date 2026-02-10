//
//  EventDetailInlineView.swift
//  NepaliDaateMenuBar
//
//  Inline event detail view that appears at the bottom of the calendar
//

import SwiftUI
import EventKit

struct EventDetailInlineView: View {
    let event: EKEvent
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and close button
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(eventColor)
                        .frame(width: 3, height: 18)
                    
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            // Meeting Link Button
            if let meetingURL = meetingURL {
                Button(action: {
                    NSWorkspace.shared.open(meetingURL)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 11))
                        Text(meetingLinkText(for: meetingURL))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("Join")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Time and Date
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                        .frame(width: 14)
                    Text(eventTimeString)
                        .font(.system(size: 11))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                        .frame(width: 14)
                    Text(eventDateString)
                        .font(.system(size: 11))
                }
            }
            
            // Location
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                        .frame(width: 14)
                    Text(location)
                        .font(.system(size: 11))
                        .lineLimit(2)
                }
            }
            
            // Notes (plain text only, no HTML)
            if let notes = event.notes, !notes.isEmpty {
                Divider()
                
                Text(notes.stripHTML())
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Helpers
    
    private var eventColor: Color {
        if let calendar = event.calendar {
            return Color(calendar.color)
        }
        return .blue
    }
    
    private var eventDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: event.startDate)
    }
    
    private var eventTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) – \(end)"
    }
    
    private var meetingURL: URL? {
        // Check event URL first
        if let url = event.url, isMeetingURL(url) {
            return url
        }
        
        // Then check notes for meeting links
        if let notes = event.notes {
            return findMeetingURL(in: notes)
        }
        
        return nil
    }
    
    private func isMeetingURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us") ||
               host.contains("meet.google.com") ||
               host.contains("teams.microsoft.com")
    }
    
    private func findMeetingURL(in text: String) -> URL? {
        let patterns = [
            "https://[a-zA-Z0-9.-]*zoom\\.us/j/[0-9?=@&]+",
            "https://meet\\.google\\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}",
            "https://teams\\.microsoft\\.com/l/meetup-join/[a-zA-Z0-9%./?=&-]+"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .regularExpression),
               let url = URL(string: String(text[range])) {
                return url
            }
        }
        
        return nil
    }
    
    private func meetingLinkText(for url: URL) -> String {
        let host = url.host?.lowercased() ?? ""
        if host.contains("zoom.us") { return "Zoom Meeting" }
        if host.contains("meet.google.com") { return "Google Meet" }
        if host.contains("teams.microsoft.com") { return "Microsoft Teams" }
        return "Join Meeting"
    }
}

// Helper extension to strip HTML tags
extension String {
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
