//
//  DateFormatSettings.swift
//  NepaliDaateMenuBar
//
//  Manages date format preferences
//

import Foundation
import Combine

class DateFormatSettings: ObservableObject {
    static let shared = DateFormatSettings()
    
    @Published var formatType: DateFormatType {
        didSet {
            UserDefaults.standard.set(formatType.rawValue, forKey: Constants.UserDefaultsKeys.dateFormatType)
            updatePatternIfNeeded()
            TelemetryManager.shared.track("settings.format.changed", with: ["format": formatType.rawValue])
        }
    }
    
    @Published var customPattern: String {
        didSet {
            UserDefaults.standard.set(customPattern, forKey: Constants.UserDefaultsKeys.customFormatPattern)
            TelemetryManager.shared.track("settings.format.custom_pattern.changed")
        }
    }
    
    @Published var showTithi: Bool {
        didSet {
            UserDefaults.standard.set(showTithi, forKey: "showTithi")
            TelemetryManager.shared.track("settings.format.show_tithi.changed", with: ["enabled": String(showTithi)])
        }
    }
    
    private init() {
        let savedType = Self.loadSavedFormatType()
        self.formatType = savedType
        self.customPattern = Self.loadSavedPattern(for: savedType)
        
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "showTithi") == nil {
            self.showTithi = true
        } else {
            self.showTithi = UserDefaults.standard.bool(forKey: "showTithi")
        }
    }
    
    private static func loadSavedFormatType() -> DateFormatType {
        if let savedString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.dateFormatType),
           let type = DateFormatType(rawValue: savedString) {
            return type
        }
        return .medium
    }
    
    private static func loadSavedPattern(for formatType: DateFormatType) -> String {
        if let savedPattern = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.customFormatPattern) {
            return savedPattern
        }
        return formatType.formatPattern(for: LanguageSettings.shared.language)
    }
    
    private func updatePatternIfNeeded() {
        if formatType != .custom {
            customPattern = formatType.formatPattern(for: LanguageSettings.shared.language)
        }
    }
    
    /// Format a Nepali date using the current settings
    func format(_ date: NepaliDate) -> String {
        let language = LanguageSettings.shared.language
        let pattern = formatType == .custom ? customPattern : formatType.formatPattern(for: language)
        var result = date.formatted(pattern: pattern)
        
        if showTithi, let tithi = date.tithi, !tithi.isEmpty {
            result += ", \(tithi)"
        }
        
        return result
    }
    
    /// Get formatted date string for menu bar
    func formatForMenuBar(_ date: NepaliDate) -> String {
        return format(date)
    }
}

