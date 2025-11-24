//
//  Language.swift
//  NepaliDaateMenuBar
//
//  Language preference enumeration
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case nepali = "Nepali"
    case english = "English"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nepali:
            return "नेपाली"
        case .english:
            return "English"
        }
    }
}

