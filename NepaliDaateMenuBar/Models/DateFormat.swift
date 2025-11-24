//
//  DateFormat.swift
//  NepaliDaateMenuBar
//
//  Date format enumeration and configurations
//

import Foundation

enum DateFormatType: String, CaseIterable, Identifiable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    case monthDay = "Month, Day"
    case dayOnly = "Day Only"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    func example(for language: AppLanguage) -> String {
        switch self {
        case .short:
            return language == .nepali ? "२०८२/०८/०१" : "2082/08/01"
        case .medium:
            return language == .nepali ? "२०८२ माघ १" : "2082 Magh 1"
        case .long:
            return language == .nepali ? "माघ १, २०८२" : "Magh 1, 2082"
        case .monthDay:
            return language == .nepali ? "माघ, १" : "Magh, 1"
        case .dayOnly:
            return language == .nepali ? "१" : "1"
        case .custom:
            return "Custom..."
        }
    }
    
    func formatPattern(for language: AppLanguage) -> String {
        // Same patterns for both languages - language controls output
        switch self {
        case .short:
            return "YYYY/MM/DD"
        case .medium:
            return "YYYY MMMM D"
        case .long:
            return "MMMM D, YYYY"
        case .monthDay:
            return "MMMM, D"
        case .dayOnly:
            return "D"
        case .custom:
            return "" // User defined
        }
    }
}

extension NepaliDate {
    /// Format date using pattern string
    /// Language controls numerals and month script
    func formatted(pattern: String) -> String {
        let language = LanguageSettings.shared.language
        var result = pattern
        
        // Replace in order: longest patterns first
        result = result.replacingOccurrences(of: "YYYY", with: NumeralConverter.convert(year, for: language))
        result = result.replacingOccurrences(of: "MMMM", with: monthName)
        result = result.replacingOccurrences(of: "MM", with: NumeralConverter.convert(String(format: "%02d", month), for: language))
        result = result.replacingOccurrences(of: "DD", with: NumeralConverter.convert(String(format: "%02d", day), for: language))
        result = result.replacingOccurrences(of: "D", with: NumeralConverter.convert(day, for: language))
        
        return result
    }
}

