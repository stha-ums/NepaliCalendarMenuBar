//
//  NumeralConverter.swift
//  NepaliDaateMenuBar
//
//  Utility for converting between Latin and Devanagari numerals
//

import Foundation

struct NumeralConverter {
    private static let numeralMap: [Character: String] = [
        "0": "०", "1": "१", "2": "२", "3": "३", "4": "४",
        "5": "५", "6": "६", "7": "७", "8": "८", "9": "९"
    ]
    
    /// Convert any number to Nepali Devanagari numerals
    static func toNepali(_ value: Any) -> String {
        let stringValue = "\(value)"
        return stringValue.map { numeralMap[$0] ?? String($0) }.joined()
    }
    
    /// Convert Latin numerals to Devanagari based on language setting
    static func convert(_ value: Any, for language: AppLanguage) -> String {
        if language == .nepali {
            return toNepali(value)
        } else {
            return "\(value)"
        }
    }
}

