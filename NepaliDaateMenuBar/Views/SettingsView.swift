//
//  SettingsView.swift
//  NepaliDaateMenuBar
//
//  Minimal elegant settings view
//

import SwiftUI
import EventKit

struct SettingsView: View {
    @ObservedObject var launchOnLoginManager: LaunchOnLoginManager
    @ObservedObject var eventManager: CalendarEventManager
    @StateObject private var formatSettings: DateFormatSettings = DateFormatSettings.shared
    @StateObject private var languageSettings: LanguageSettings = LanguageSettings.shared
    @State private var previewDate: NepaliDate? = NepaliDateConverter.getCurrentNepaliDate()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Language
                OnboardingStyleSection(title: "LANGUAGE") {
                    VStack(spacing: 8) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Button(action: {
                                languageSettings.language = lang
                            }) {
                                HStack {
                                    Text(lang.displayName)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    if languageSettings.language == lang {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(languageSettings.language == lang ? 
                                              Color.accentColor.opacity(0.1) : 
                                              Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Display Format
                OnboardingStyleSection(title: "DISPLAY FORMAT") {
                    VStack(spacing: 10) {
                        ForEach(DateFormatType.allCases.filter { $0 != .custom }, id: \.self) { type in
                            FormatOptionRow(
                                type: type,
                                language: languageSettings.language,
                                showTithi: formatSettings.showTithi,
                                isSelected: formatSettings.formatType == type,
                                onSelect: { formatSettings.formatType = type }
                            )
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: formatSettings.showTithi)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Toggle(isOn: $formatSettings.showTithi) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Show Tithi")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Append lunar day to the date")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .toggleStyle(.switch)
                        .padding(.horizontal, 4)
                        
                        // Preview
                        if let date = previewDate {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Preview:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatSettings.format(date))
                                    .font(.system(size: 13, weight: .medium))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formatSettings.showTithi)
                            }
                            .padding(8)
                            .background(Color.accentColor.opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // General
                OnboardingStyleSection(title: "GENERAL") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Toggle(isOn: $launchOnLoginManager.isEnabled) {
                                Text("Launch on Login")
                                    .font(.system(size: 12))
                            }
                            .toggleStyle(.switch)
                            
                            Spacer()
                            
                            Button(action: {
                                launchOnLoginManager.openLoginItemsSettings()
                                TelemetryManager.shared.track("settings.launch_at_login.manual_settings_opened")
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "gearshape")
                                    Text("Open Settings")
                                }
                                .font(.system(size: 10))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        
                        if #available(macOS 13.0, *) {
                            Text("Status reflects actual system state. Toggle will automatically register/unregister the app.")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("For macOS 12 and earlier: Manually add this app to Login Items in System Settings")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                // Calendar
                OnboardingStyleSection(title: "CALENDAR") {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(authorizationStatusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(authorizationStatusText)
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        if !hasCalendarAccess {
                            Button("Grant") {
                                Task {
                                    _ = await eventManager.requestAccess()
                                }
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                        }
                    }
                }
                
                // Updates
                OnboardingStyleSection(title: "UPDATES") {
                    UpdatesSettingsRow()
                }
                
                Spacer()
                
                // Development/Reset Section
                VStack(spacing: 8) {
                    Button(action: resetSettings) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Settings")
                        }
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)
                    
                    Text("Reset to default settings and show onboarding again")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Quit
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func resetSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings?"
        alert.informativeText = "This will reset all preferences and show the onboarding wizard again when you restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Clear all UserDefaults
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
            }
            
            // Reset managers
            OnboardingManager.shared.resetOnboarding()
            TelemetryManager.shared.track("settings.reset_clicked")
            
            // Show confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Settings Reset"
            confirmAlert.informativeText = "All settings have been reset. Please quit and restart the app to see the onboarding wizard."
            confirmAlert.alertStyle = .informational
            confirmAlert.runModal()
        }
    }
    
    // MARK: - Helpers
    
    private var hasCalendarAccess: Bool {
        if #available(macOS 14.0, *) {
            return eventManager.authorizationStatus == EKAuthorizationStatus.fullAccess || 
                   eventManager.authorizationStatus == EKAuthorizationStatus.writeOnly
        } else {
            return eventManager.authorizationStatus == EKAuthorizationStatus.authorized
        }
    }
    
    private var authorizationStatusText: String {
        if #available(macOS 14.0, *) {
            switch eventManager.authorizationStatus {
            case .fullAccess: return "Full Access"
            case .writeOnly: return "Write Only"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            case .authorized: return "Authorized"
            @unknown default: return "Unknown"
            }
        } else {
            switch eventManager.authorizationStatus {
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .notDetermined: return "Not Determined"
            case .fullAccess: return "Full Access"
            case .writeOnly: return "Write Only"
            @unknown default: return "Unknown"
            }
        }
    }
    
    private var authorizationStatusColor: Color {
        if #available(macOS 14.0, *) {
            switch eventManager.authorizationStatus {
            case .fullAccess, .authorized: return .green
            case .writeOnly: return .blue
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            @unknown default: return .gray
            }
        } else {
            switch eventManager.authorizationStatus {
            case .authorized: return .green
            case .denied, .restricted: return .red
            case .notDetermined: return .orange
            case .fullAccess: return .green
            case .writeOnly: return .blue
            @unknown default: return .gray
            }
        }
    }
}

// Onboarding-style section for settings
struct OnboardingStyleSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            content
        }
    }
}

// Format option row matching onboarding style
struct FormatOptionRow: View {
    let type: DateFormatType
    let language: AppLanguage
    let showTithi: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(type.example(for: language, showTithi: showTithi))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          Color.accentColor.opacity(0.1) : 
                          Color(NSColor.controlBackgroundColor).opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? 
                           Color.accentColor.opacity(0.4) : 
                           Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct UpdatesSettingsRow: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
#if SPARKLE
            Toggle(isOn: binding) {
                Text("Automatically check for updates")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            
            Text("The app will automatically check for GitHub release updates.")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
#else
            Toggle(isOn: $updateManager.isAppStoreCheckEnabled) {
                Text("Notify about new versions")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            
            Text("The app will check the App Store for new versions on launch.")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
#endif
        }
    }
    
#if SPARKLE
    private var binding: Binding<Bool> {
        Binding(
            get: { updateManager.automaticallyChecksForUpdates },
            set: { updateManager.automaticallyChecksForUpdates = $0 }
        )
    }
#endif
}

