//
//  OnboardingView.swift
//  NepaliDaateMenuBar
//
//  Minimal and elegant onboarding wizard
//

import SwiftUI
import EventKit

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var formatSettings = DateFormatSettings.shared
    @StateObject private var languageSettings = LanguageSettings.shared
    @StateObject private var eventManager = CalendarEventManager.shared
    @StateObject private var launchOnLoginManager = LaunchOnLoginManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<onboardingManager.totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= onboardingManager.currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
            
            // Content with manual step switching
            ZStack {
                if onboardingManager.currentStep == 0 {
                    WelcomeStep()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else if onboardingManager.currentStep == 1 {
                    LanguageStep(languageSettings: languageSettings)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else if onboardingManager.currentStep == 2 {
                    DateFormatStep(formatSettings: formatSettings, languageSettings: languageSettings)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else if onboardingManager.currentStep == 3 {
                    CalendarStep(eventManager: eventManager)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else if onboardingManager.currentStep == 4 {
                    LaunchOnLoginStep(launchOnLoginManager: launchOnLoginManager)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else if onboardingManager.currentStep == 5 {
                    FinalStep(onComplete: {
                        onboardingManager.completeOnboarding()
                        dismiss()
                    })
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: onboardingManager.currentStep)
            
            // Navigation
            HStack(spacing: 12) {
                if onboardingManager.currentStep > 0 {
                    Button("Back") {
                        onboardingManager.previousStep()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
                
                if onboardingManager.currentStep < onboardingManager.totalSteps - 1 {
                    Button("Continue") {
                        onboardingManager.nextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Get Started") {
                        onboardingManager.completeOnboarding()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(20)
            
            Spacer(minLength: 0)
        }
        .frame(width: Constants.Window.onboardingWidth, height: Constants.Window.onboardingHeight, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 6) {
                Text("Welcome to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Nepali Date Menu Bar")
                    .font(.title2.weight(.bold))
            }
            
            Text("Display Nepali (Bikram Sambat) dates\nin your menu bar with calendar integration")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Language Step

struct LanguageStep: View {
    @ObservedObject var languageSettings: LanguageSettings
    @State private var previewDate: NepaliDate? = NepaliDateConverter.getCurrentNepaliDate()
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            
            headerSection
            languageOptions
            
            Spacer()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 42))
                .foregroundColor(.accentColor)
            
            Text("Choose Language")
                .font(.title3.weight(.semibold))
            
            Text("Select how month names are displayed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var languageOptions: some View {
        VStack(spacing: 8) {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                languageOptionButton(for: lang)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private func languageOptionButton(for lang: AppLanguage) -> some View {
        let isSelected = languageSettings.language == lang
        let backgroundColor = isSelected ? 
            Color.accentColor.opacity(0.1) : 
            Color(NSColor.controlBackgroundColor).opacity(0.3)
        let borderColor = isSelected ? 
            Color.accentColor.opacity(0.4) : 
            Color.clear
        
        return Button(action: {
            languageSettings.language = lang
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lang.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let date = previewDate {
                        Text(previewText(for: date, language: lang))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(backgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(borderColor, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
    
    private func previewText(for date: NepaliDate, language: AppLanguage) -> String {
        if language == .nepali {
            let yearStr = NumeralConverter.toNepali(date.year)
            let dayStr = NumeralConverter.toNepali(date.day)
            return "\(yearStr) \(date.nepaliMonthName) \(dayStr)"
        } else {
            return String(format: "%d %@ %d", date.year, date.englishMonthName, date.day)
        }
    }
}

// MARK: - Date Format Step

struct DateFormatStep: View {
    @ObservedObject var formatSettings: DateFormatSettings
    @ObservedObject var languageSettings: LanguageSettings
    @State private var previewDate: NepaliDate? = NepaliDateConverter.getCurrentNepaliDate()
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            
            VStack(spacing: 10) {
                Image(systemName: "textformat")
                    .font(.system(size: 42))
                    .foregroundColor(.accentColor)
                
                Text("Choose Display Format")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("How the date appears in your menu bar")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(DateFormatType.allCases.filter { $0 != .custom && $0 != .dayOnly && $0 != .monthDay}, id: \.self) { type in
                    Button(action: {
                        formatSettings.formatType = type
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(type.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(type.example(for: languageSettings.language))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if formatSettings.formatType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(formatSettings.formatType == type ? 
                                      Color.accentColor.opacity(0.1) : 
                                      Color(NSColor.controlBackgroundColor).opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(formatSettings.formatType == type ? 
                                       Color.accentColor.opacity(0.4) : 
                                       Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Calendar Step

struct CalendarStep: View {
    @ObservedObject var eventManager: CalendarEventManager
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            
            VStack(spacing: 10) {
                Image(systemName: hasAccess ? "checkmark.circle.fill" : "calendar.badge.clock")
                    .font(.system(size: 42))
                    .foregroundColor(hasAccess ? .green : .accentColor)
                
                Text("Calendar Integration")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(hasAccess ? 
                     "Calendar access granted successfully" :
                     "View your events (read-only)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasAccess {
                Button(action: {
                    isRequesting = true
                    Task {
                        _ = await eventManager.requestAccess()
                        isRequesting = false
                    }
                }) {
                    Label(isRequesting ? "Requesting..." : "Grant Calendar Access", 
                          systemImage: "calendar")
                        .font(.system(size: 12))
                        .frame(maxWidth: 240)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
            }
            
            Text("Optional - can be enabled later in settings")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var hasAccess: Bool {
        if #available(macOS 14.0, *) {
            return eventManager.authorizationStatus == .fullAccess || 
                   eventManager.authorizationStatus == .writeOnly
        } else {
            return eventManager.authorizationStatus == .authorized
        }
    }
}

// MARK: - Launch on Login Step

struct LaunchOnLoginStep: View {
    @ObservedObject var launchOnLoginManager: LaunchOnLoginManager
    @State private var wantsLaunchOnLogin = false
    
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            
            VStack(spacing: 10) {
                Image(systemName: wantsLaunchOnLogin ? "checkmark.circle.fill" : "power.circle")
                    .font(.system(size: 42))
                    .foregroundColor(wantsLaunchOnLogin ? .green : .accentColor)
                
                Text("Launch on Login")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Start the app automatically when you log in")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    wantsLaunchOnLogin = true
                    launchOnLoginManager.isEnabled = true
                }) {
                    HStack {
                        Text("Yes, launch on login")
                            .font(.system(size: 12))
                        Spacer()
                        if wantsLaunchOnLogin {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(wantsLaunchOnLogin ? 
                                  Color.accentColor.opacity(0.1) : 
                                  Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(wantsLaunchOnLogin ? 
                                   Color.accentColor.opacity(0.4) : 
                                   Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    wantsLaunchOnLogin = false
                    launchOnLoginManager.isEnabled = false
                }) {
                    HStack {
                        Text("No, I'll start it manually")
                            .font(.system(size: 12))
                        Spacer()
                        if !wantsLaunchOnLogin {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(!wantsLaunchOnLogin ? 
                                  Color.accentColor.opacity(0.1) : 
                                  Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(!wantsLaunchOnLogin ? 
                                   Color.accentColor.opacity(0.4) : 
                                   Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            
            Text("You can change this later in settings")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.6))
            
            Spacer()
        }
    }
}

// MARK: - Final Step

struct FinalStep: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                
                Text("You're All Set!")
                    .font(.system(size: 20, weight: .bold))
                
                Text("The Nepali date will now appear in your menu bar")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(icon: "hand.tap", text: "Left-click to view calendar")
                TipRow(icon: "hand.point.up.left", text: "Right-click for settings")
                TipRow(icon: "gear", text: "Customize anytime in settings")
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

