//
//  NepaliDate.swift
//  NepaliDaateMenuBar
//
//  Nepali Date Model
//

import Foundation

struct NepaliDate {
    let year: Int
    let month: Int
    let day: Int
    
    var monthName: String {
        let language = LanguageSettings.shared.language
        
        if language == .nepali {
            let months = ["बैशाख", "जेठ", "असार", "साउन", "भदौ", "आश्विन", 
                         "कार्तिक", "मंसिर", "पुष", "माघ", "फाल्गुण", "चैत"]
            guard month >= 1 && month <= 12 else { return "" }
            return months[month - 1]
        } else {
            let months = ["Baishakh", "Jeth", "Ashar", "Shrawan", "Bhadra", "Ashwin",
                         "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
            guard month >= 1 && month <= 12 else { return "" }
            return months[month - 1]
        }
    }
    
    var nepaliMonthName: String {
        let months = ["बैशाख", "जेठ", "असार", "साउन", "भदौ", "आश्विन", 
                     "कार्तिक", "मंसिर", "पुष", "माघ", "फाल्गुण", "चैत"]
        guard month >= 1 && month <= 12 else { return "" }
        return months[month - 1]
    }
    
    var englishMonthName: String {
        let months = ["Baishakh", "Jeth", "Ashar", "Shrawan", "Bhadra", "Ashwin",
                     "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"]
        guard month >= 1 && month <= 12 else { return "" }
        return months[month - 1]
    }
    
    var formattedDate: String {
        let language = LanguageSettings.shared.language
        let yearStr = NumeralConverter.convert(year, for: language)
        let dayStr = NumeralConverter.convert(day, for: language)
        return "\(yearStr) \(monthName) \(dayStr)"
    }
    
    var shortFormattedDate: String {
        let language = LanguageSettings.shared.language
        let yearStr = NumeralConverter.convert(year, for: language)
        let monthStr = NumeralConverter.convert(String(format: "%02d", month), for: language)
        let dayStr = NumeralConverter.convert(String(format: "%02d", day), for: language)
        return "\(yearStr)/\(monthStr)/\(dayStr)"
    }
}

