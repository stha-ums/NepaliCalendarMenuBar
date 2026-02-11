//
//  EventDetailPopup.swift
//  NepaliDaateMenuBar
//
//  A popup view to display event details, similar to Apple Calendar.
//

import SwiftUI
import EventKit

struct EventDetailPopup: View {
    let event: EKEvent
    var onClose: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Title and Close button
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(event.swiftUIColor)
                        .frame(width: 4, height: 24)
                    
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: { 
                    dismiss()
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            
            // Meeting Link Button
            if let meetingURL = meetingURL {
                Button(action: {
                    TelemetryManager.shared.track("calendar.event.join_meeting_clicked")
                    NSWorkspace.shared.open(meetingURL)
                    // Close the popup
                    dismiss()
                    onClose?()
                    // Then close the app after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NSApplication.shared.terminate(nil)
                    }
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                        Text(meetingLinkText(for: meetingURL))
                        Spacer()
                        Text("Join")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            
            Divider()
            
            // Time and Date
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eventDateString)
                            .font(.subheadline)
                        Text(nepaliDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text(eventTimeString)
                        .font(.subheadline)
                }
            }
            
            // Location
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text(location)
                        .font(.subheadline)
                }
            }
            
            // Notes
            if let notes = event.notes, !notes.isEmpty {
                Divider()
                
                ScrollView(showsIndicators: false) {
                    HTMLTextView(html: notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 250)
            }
            
            // Attendees
            if let attendees = event.attendees, !attendees.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Text("Attendees (\(attendees.count))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        AttendeeChipField(attendees: attendees)
                            .padding(.vertical, 4)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 180)
                 }
            }
        }
        .padding(16)
        .frame(width: 340)
        .frame(maxHeight: (NSScreen.main?.visibleFrame.height ?? 800) * 0.8)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helpers
    
    private var eventDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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
    
    private var nepaliDateString: String {
        guard let nepaliDate = NepaliDateConverter.convertToNepali(gregorianDate: event.startDate) else { return "" }
        
        let dateStr = nepaliDate.fullFormattedDate(with: event.startDate)
        let tithi = NepaliDateConverter.getTithiName(for: event.startDate) ?? ""
        
        if tithi.isEmpty {
            return dateStr
        } else {
            return "\(dateStr) (\(tithi))"
        }
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
    
    /// Cleans HTML and special characters from notes
    private func cleanNotes(_ html: String) -> String {
        var text = html
        
        // Remove HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Remove those ~:~:~:~ separators
        text = text.replacingOccurrences(of: "-:~:~:~:~[^~]*~:~:~:~:-", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "~:~:~[^~]*~:~:~", with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        
        // Clean up excessive whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
    
    private func attendeeStatusIcon(for status: EKParticipantStatus) -> some View {
        switch status {
        case .accepted:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .declined:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .tentative:
            return Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.orange)
        case .pending:
            return Image(systemName: "circle")
                .foregroundColor(.secondary)
        default:
            return Image(systemName: "person.circle")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Attendee Chip Components

struct AttendeeChipField: View {
    let attendees: [EKParticipant]
    
    var body: some View {
        // Simple chip field using Flow layout logic (approximated with LazyVGrid for now or custom)
        // Since we don't have a built-in Flow layout in older SwiftUI, we'll use a LazyVGrid with small columns or a custom view.
        // For simplicity and 100% correctness in layout, let's use a nested HStack/VStack or a single column if grid is too rigid.
        // Actually, let's just use a simple vertical list but styled as chips as a fallback, or a custom flow layout.
        
        VStack(alignment: .leading, spacing: 6) {
            // We'll wrap them manually or use a simple grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 6) {
                ForEach(attendees, id: \.self) { attendee in
                    AttendeeChip(attendee: attendee)
                }
            }
        }
    }
}

struct AttendeeChip: View {
    let attendee: EKParticipant
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
                .font(.system(size: 8))
            
            Text(attendee.name ?? "Unknown")
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            
            if attendee.isCurrentUser {
                Text("(Me)")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
        .help(attendee.name ?? "Unknown")
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch attendee.participantStatus {
        case .accepted:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .declined:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        case .tentative:
            Image(systemName: "questionmark.circle.fill").foregroundColor(.orange)
        default:
            Image(systemName: "circle").foregroundColor(.secondary)
        }
    }
}
