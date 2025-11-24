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
        }
    }
    
    @Published var customPattern: String {
        didSet {
            UserDefaults.standard.set(customPattern, forKey: Constants.UserDefaultsKeys.customFormatPattern)
        }
    }
    
    private init() {
        let savedType = Self.loadSavedFormatType()
        self.formatType = savedType
        self.customPattern = Self.loadSavedPattern(for: savedType)
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
        return date.formatted(pattern: pattern)
    }
    
    /// Get formatted date string for menu bar
    func formatForMenuBar(_ date: NepaliDate) -> String {
        return format(date)
    }
}

