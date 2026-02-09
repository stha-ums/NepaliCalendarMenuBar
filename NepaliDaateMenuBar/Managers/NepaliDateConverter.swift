import Foundation

class NepaliDateConverter {
    // MARK: - Calendar Engine
    
    private static let engine = createEngine()
    
    // MARK: - AD to BS Conversion
    
    /// Convert Gregorian date to Nepali date
    static func convertToNepali(gregorianDate: Date = Date()) -> NepaliDate? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }
        
        return convertToNepali(year: year, month: month, day: day)
    }
    
    /// Convert Gregorian date components to Nepali date
    static func convertToNepali(year: Int, month: Int, day: Int) -> NepaliDate? {
        let gDate = GregorianDate(year: Int32(year), month: UInt32(month), day: UInt32(day))
        
        do {
            let bsDate = try engine.gregorianToBs(date: gDate)
            return NepaliDate(year: Int(bsDate.year), month: Int(bsDate.month), day: Int(bsDate.day))
        } catch {
            print("Error converting AD to BS: \(error)")
            return nil
        }
    }
    
    // MARK: - BS to AD Conversion
    
    /// Convert Nepali date to Gregorian date
    static func convertNepaliToGregorian(nepaliDate: NepaliDate) -> Date? {
        let bsDate = BsDate(year: UInt16(nepaliDate.year), month: UInt8(nepaliDate.month), day: UInt8(nepaliDate.day))
        
        do {
            let gDate = try engine.bsToGregorian(date: bsDate)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone.current
            return calendar.date(from: DateComponents(year: Int(gDate.year), month: Int(gDate.month), day: Int(gDate.day)))
        } catch {
            print("Error converting BS to AD: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get current Nepali date
    static func getCurrentNepaliDate() -> NepaliDate? {
        return convertToNepali(gregorianDate: Date())
    }
    
    /// Get number of days in a Nepali month
    static func getDaysInMonth(year: Int, month: Int) -> Int {
        let dummyLocation = Location(latitude: 27.7172, longitude: 85.3240) // Kathmandu
        do {
            let monthData = try engine.getMonthCalendar(year: UInt16(year), month: UInt8(month), location: dummyLocation)
            return Int(monthData.daysInMonth)
        } catch {
            print("Error getting days in month: \(error)")
            return 30 // Fallback
        }
    }

    /// Get full month calendar data including astronomical info
    static func getMonthCalendarData(year: Int, month: Int) -> [CalendarDayInfo] {
        let appLang = LanguageSettings.shared.language
        let engineLang = mapLanguage(appLang)
        let dummyLocation = Location(latitude: 27.7172, longitude: 85.3240)
        
        do {
            let monthData = try engine.getMonthCalendar(year: UInt16(year), month: UInt8(month), location: dummyLocation)
            var grid: [CalendarDayInfo] = []
            
            // Add leading padding
            for _ in 0..<Int(monthData.startDayOfWeek) {
                grid.append(CalendarDayInfo(nepaliDate: nil, gregorianDate: nil, isCurrentMonth: false))
            }
            
            // Add month days
            for day in monthData.days {
                let nepaliDate = NepaliDate(year: Int(day.bsYear), month: Int(day.bsMonth), day: Int(day.bsDay))
                
                // GregorianDate to Date
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone.current
                let components = DateComponents(year: Int(day.gregorianDate.year), month: Int(day.gregorianDate.month), day: Int(day.gregorianDate.day))
                let gregorianDate = calendar.date(from: components)
                
                var dayInfo = CalendarDayInfo(
                    nepaliDate: nepaliDate,
                    gregorianDate: gregorianDate,
                    isCurrentMonth: true
                )
                
                // Fetch localized names
                dayInfo.tithiName = try? engine.getTithiName(tithi: day.tithi, lang: engineLang)
                dayInfo.nakshatraName = try? engine.getNakshatraName(nakshatra: day.nakshatra, lang: engineLang)
                dayInfo.rashiName = try? engine.getZodiacName(zodiac: day.moonSign, lang: engineLang)
                
                // Fetch and format Sunrise/Sunset
                if let sunrise = try? engine.getSunrise(date: day.gregorianDate, location: dummyLocation) {
                    dayInfo.sunrise = String(format: "%02d:%02d", sunrise.hour, sunrise.minute)
                }
                if let sunset = try? engine.getSunset(date: day.gregorianDate, location: dummyLocation) {
                    dayInfo.sunset = String(format: "%02d:%02d", sunset.hour, sunset.minute)
                }
                
                grid.append(dayInfo)
            }
            
            // Add trailing padding to fill Constants.Grid.totalCells (42)
            while grid.count < Constants.Grid.totalCells {
                grid.append(CalendarDayInfo(nepaliDate: nil, gregorianDate: nil, isCurrentMonth: false))
            }
            
            return grid
        } catch {
            print("Error getting month calendar data: \(error)")
            return []
        }
    }

    /// Get localized Tithi name for any Gregorian date
    static func getTithiName(for date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }
        
        let gDate = GregorianDate(year: Int32(year), month: UInt32(month), day: UInt32(day))
        let engineLang = mapLanguage(LanguageSettings.shared.language)
        
        do {
            let tithi = try engine.getTithi(date: gDate)
            return engine.getTithiName(tithi: tithi, lang: engineLang)
        } catch {
            print("Error getting Tithi name: \(error)")
            return nil
        }
    }

    private static func mapLanguage(_ appLang: AppLanguage) -> Language {
        switch appLang {
        case .english: return .english
        case .nepali: return .nepali
        }
    }
}
