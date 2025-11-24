//
//  Constants.swift
//  NepaliDaateMenuBar
//
//  App-wide constants
//

import Foundation

enum Constants {
    // MARK: - Window Sizes
    enum Window {
        static let popoverWidth: CGFloat = 360
        static let popoverHeight: CGFloat = 498
        static let settingsWidth: CGFloat = 400
        static let settingsHeight: CGFloat = 500
        static let onboardingWidth: CGFloat = 420
        static let onboardingHeight: CGFloat = 460
        static let aboutWidth: CGFloat = 480
        static let aboutHeight: CGFloat = 600
    }
    
    // MARK: - Schedule View
    enum Schedule {
        static let initialPastDays = -30
        static let initialFutureDays = 60
        static let loadMoreThresholdTop = 5
        static let loadMoreThresholdBottom = 10
        static let loadMoreBatchSize = 30
    }
    
    // MARK: - Calendar Grid
    enum Grid {
        static let totalCells = 42
        static let daysPerWeek = 7
        static let cellHeight: CGFloat = 40
        static let gridSpacing: CGFloat = 2
    }
    
    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let dateFormatType = "dateFormatType"
        static let customFormatPattern = "customFormatPattern"
        static let appLanguage = "appLanguage"
        static let launchOnLogin = "launchOnLogin"
    }
    
    // MARK: - Nepali Weekdays
    enum Weekdays {
        static let nepali = ["आइत", "सोम", "मंगल", "बुध", "बिहि", "शुक्र", "शनि"]
        static let nepaliShort = ["आ", "सो", "मं", "बु", "बि", "शु", "श"]
        static let english = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        static let englishShort = ["S", "M", "T", "W", "T", "F", "S"]
    }
}

