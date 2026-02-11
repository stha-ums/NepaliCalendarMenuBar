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
    case dayMonth = "Day, Month"
    case dayOnly = "Day"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    func example(for language: AppLanguage, showTithi: Bool = false) -> String {
        var baseExample = ""
        switch self {
        case .short:
            baseExample = language == .nepali ? "२०८२/०८/०१" : "2082/08/01"
        case .medium:
            baseExample = language == .nepali ? "२०८२ माघ १" : "2082 Magh 1"
        case .long:
            baseExample = language == .nepali ? "माघ १, २०८२" : "Magh 1, 2082"
        case .dayMonth:
            baseExample = language == .nepali ? "मंसिर १३" : "13th Mangsir"
        case .dayOnly:
            baseExample = language == .nepali ? "१३" : "13"
        case .custom:
            return "Custom..."
        }
        
        if showTithi {
            let tithiSample = language == .nepali ? "अष्टमी" : "Ashtami"
            return "\(baseExample), \(tithiSample)"
        }
        
        return baseExample
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
        case .dayMonth:
            return language == .nepali ? "MMMM D" : "Do MMMM"
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
        
        // Ordinal day (e.g. 1st, 2nd...)
        if result.contains("Do") {
            let dayStr = NumeralConverter.convert(day, for: language)
            if language == .english {
                result = result.replacingOccurrences(of: "Do", with: "\(dayStr)\(ordinalSuffix(for: day))")
            } else {
                result = result.replacingOccurrences(of: "Do", with: dayStr)
            }
        }
        
        // Replace in order: longest patterns first
        result = result.replacingOccurrences(of: "YYYY", with: NumeralConverter.convert(year, for: language))
        result = result.replacingOccurrences(of: "MMMM", with: monthName)
        result = result.replacingOccurrences(of: "MM", with: NumeralConverter.convert(String(format: "%02d", month), for: language))
        result = result.replacingOccurrences(of: "DD", with: NumeralConverter.convert(String(format: "%02d", day), for: language))
        result = result.replacingOccurrences(of: "D", with: NumeralConverter.convert(day, for: language))
        
        return result
    }
    
    private func ordinalSuffix(for day: Int) -> String {
        let j = day % 10
        let k = day % 100
        if j == 1 && k != 11 {
            return "st"
        }
        if j == 2 && k != 12 {
            return "nd"
        }
        if j == 3 && k != 13 {
            return "rd"
        }
        return "th"
    }
}

