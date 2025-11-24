//
//  LanguageSettings.swift
//  NepaliDaateMenuBar
//
//  Manages language preferences
//

import Foundation
import Combine

class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()
    
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Constants.UserDefaultsKeys.appLanguage)
            updateFormatPattern()
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.appLanguage),
           let lang = AppLanguage(rawValue: savedLanguage) {
            self.language = lang
        } else {
            self.language = .nepali
        }
    }
    
    private func updateFormatPattern() {
        let currentFormat = DateFormatSettings.shared.formatType
        if currentFormat != .custom {
            DateFormatSettings.shared.customPattern = currentFormat.formatPattern(for: language)
        }
    }
}

