//
//  SettingsView.swift
//  NepaliDaateMenuBar
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
            VStack(spacing: 0) {
                // MARK: Appearance
                SettingsSection(icon: "globe", title: "Language") {
                    HStack(spacing: 8) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            LanguageChip(
                                label: lang.displayName,
                                isSelected: languageSettings.language == lang
                            ) {
                                languageSettings.language = lang
                            }
                        }
                        Spacer()
                    }
                }

                SettingsDivider()

                // MARK: Date Format
                SettingsSection(icon: "calendar", title: "Date Format") {
                    VStack(spacing: 6) {
                        ForEach(DateFormatType.allCases.filter { $0 != .custom }, id: \.self) { type in
                            FormatOptionRow(
                                type: type,
                                language: languageSettings.language,
                                showTithi: formatSettings.showTithi,
                                isSelected: formatSettings.formatType == type,
                                onSelect: { formatSettings.formatType = type }
                            )
                        }

                        // Tithi toggle
                        SettingsToggleRow(
                            title: "Show Tithi",
                            subtitle: "Append lunar day to the date",
                            isOn: $formatSettings.showTithi
                        )

                        // Live preview
                        if let date = previewDate {
                            HStack {
                                Label("Preview", systemImage: "eye")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatSettings.format(date))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formatSettings.showTithi)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }

                SettingsDivider()

                // MARK: General
                SettingsSection(icon: "gearshape", title: "General") {
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            title: "Launch on Login",
                            subtitle: "Start automatically when you log in",
                            isOn: $launchOnLoginManager.isEnabled
                        )

                        Divider().padding(.vertical, 4)

                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Login Items")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Manage in System Settings")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                launchOnLoginManager.openLoginItemsSettings()
                                TelemetryManager.shared.track("settings.launch_at_login.manual_settings_opened")
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 10))
                                    Text("Open")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 2)
                    }
                }

                SettingsDivider()

                // MARK: Calendar Access
                SettingsSection(icon: "calendar.badge.clock", title: "Calendar Access") {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(authorizationStatusColor.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Circle()
                                .fill(authorizationStatusColor)
                                .frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(authorizationStatusText)
                                .font(.system(size: 12, weight: .semibold))
                            Text(authorizationStatusDescription)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if !hasCalendarAccess {
                            Button("Grant Access") {
                                Task { _ = await eventManager.requestAccess() }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(10)
                }

                SettingsDivider()

                // MARK: Updates
                SettingsSection(icon: "arrow.down.circle", title: "Updates") {
                    UpdatesSettingsRow()
                }

                SettingsDivider()

                // MARK: Danger Zone
                SettingsSection(icon: "exclamationmark.triangle", title: "Reset", tint: .orange) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Reset All Settings")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Clears preferences and shows onboarding")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: resetSettings) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10))
                                    Text("Reset")
                                        .font(.system(size: 11, weight: .medium))
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.orange)
                        }
                    }
                }

                SettingsDivider()

                // MARK: Quit
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("Quit BS Calendar")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Helpers

    private func resetSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings?"
        alert.informativeText = "This will reset all preferences and show the onboarding wizard again when you restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
            }
            OnboardingManager.shared.resetOnboarding()
            TelemetryManager.shared.track("settings.reset_clicked")

            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Settings Reset"
            confirmAlert.informativeText = "All settings have been reset. Please quit and restart the app to see the onboarding wizard."
            confirmAlert.alertStyle = .informational
            confirmAlert.runModal()
        }
    }

    private var hasCalendarAccess: Bool {
        if #available(macOS 14.0, *) {
            return eventManager.authorizationStatus == .fullAccess ||
                   eventManager.authorizationStatus == .writeOnly
        } else {
            return eventManager.authorizationStatus == .authorized
        }
    }

    private var authorizationStatusText: String {
        switch eventManager.authorizationStatus {
        case .fullAccess: return "Full Access"
        case .writeOnly: return "Write Only"
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Unknown"
        }
    }

    private var authorizationStatusDescription: String {
        switch eventManager.authorizationStatus {
        case .fullAccess, .authorized: return "Events are syncing normally"
        case .writeOnly: return "Read access not granted"
        case .denied: return "Enable in System Settings → Privacy"
        case .restricted: return "Access restricted by policy"
        case .notDetermined: return "Tap Grant Access to enable events"
        @unknown default: return ""
        }
    }

    private var authorizationStatusColor: Color {
        switch eventManager.authorizationStatus {
        case .fullAccess, .authorized: return .green
        case .writeOnly: return .blue
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let icon: String
    let title: String
    var tint: Color = .accentColor
    let content: Content

    init(icon: String, title: String, tint: Color = .accentColor, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 16)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }

            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Settings Divider

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Language Chip

struct LanguageChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 2)
    }
}

// MARK: - Format Option Row

struct FormatOptionRow: View {
    let type: DateFormatType
    let language: AppLanguage
    let showTithi: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text(type.example(for: language, showTithi: showTithi))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) :
                          isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.7) :
                          Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Updates Row

struct UpdatesSettingsRow: View {
    @ObservedObject private var updateManager = UpdateManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
#if SPARKLE
            SettingsToggleRow(
                title: "Auto-check for Updates",
                subtitle: "Automatically check for GitHub releases",
                isOn: binding
            )
#else
            SettingsToggleRow(
                title: "Notify about New Versions",
                subtitle: "Check the App Store for updates on launch",
                isOn: $updateManager.isAppStoreCheckEnabled
            )
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

// Kept for backward compatibility
struct OnboardingStyleSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        SettingsSection(icon: "circle", title: title) { content }
    }
}
