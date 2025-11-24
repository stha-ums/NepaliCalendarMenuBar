//
//  NepaliDateConverter.swift
//  NepaliDaateMenuBar
//
//  Nepali Date Conversion Algorithm
//  Based on pyBSDate - uses anchor points (1st Baisakh) for accuracy
// https://github.com/SushilShrestha/pyBSDate
//

import Foundation

class NepaliDateConverter {
    // MARK: - Calendar Data with Anchor Points
    
    // Each year has: 1st Baisakh AD date and days in each month
    // Key: BS Year, Value: (1st Baisakh AD date, [days in each month])
    static let calendarData: [Int: (firstBaisakh: (year: Int, month: Int, day: Int), daysInMonths: [Int])] = [
        2000: ((1943, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 29, 31]),
        2001: ((1944, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2002: ((1945, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2003: ((1946, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2004: ((1947, 4, 14), [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2005: ((1948, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2006: ((1949, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2007: ((1950, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2008: ((1951, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31]),
        2009: ((1952, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2010: ((1953, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2011: ((1954, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2012: ((1955, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30]),
        2013: ((1956, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2014: ((1957, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2015: ((1958, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2016: ((1959, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30]),
        2017: ((1960, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2018: ((1961, 4, 13), [31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2019: ((1962, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2020: ((1963, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2021: ((1964, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2022: ((1965, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30]),
        2023: ((1966, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2024: ((1967, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2025: ((1968, 4, 13), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2026: ((1969, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2027: ((1970, 4, 14), [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2028: ((1971, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2029: ((1972, 4, 13), [31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30]),
        2030: ((1973, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2031: ((1974, 4, 14), [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2032: ((1975, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2033: ((1976, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2034: ((1977, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2035: ((1978, 4, 14), [30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31]),
        2036: ((1979, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2037: ((1980, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2038: ((1981, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2039: ((1982, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30]),
        2040: ((1983, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2041: ((1984, 4, 13), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2042: ((1985, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2043: ((1986, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30]),
        2044: ((1987, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2045: ((1988, 4, 13), [31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2046: ((1989, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2047: ((1990, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2048: ((1991, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2049: ((1992, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30]),
        2050: ((1993, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2051: ((1994, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2052: ((1995, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2053: ((1996, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30]),
        2054: ((1997, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2055: ((1998, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2056: ((1999, 4, 14), [31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30]),
        2057: ((2000, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2058: ((2001, 4, 14), [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2059: ((2002, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2060: ((2003, 4, 14), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2061: ((2004, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2062: ((2005, 4, 14), [30, 32, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31]),
        2063: ((2006, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2064: ((2007, 4, 14), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2065: ((2008, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2066: ((2009, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31]),
        2067: ((2010, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2068: ((2011, 4, 14), [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2069: ((2012, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2070: ((2013, 4, 14), [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30]),
        2071: ((2014, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2072: ((2015, 4, 14), [31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30]),
        2073: ((2016, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31]),
        2074: ((2017, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2075: ((2018, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2076: ((2019, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30]),
        2077: ((2020, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2078: ((2021, 4, 14), [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30]),
        2079: ((2022, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2080: ((2023, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30]),
        2081: ((2024, 4, 13), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31]),
        2082: ((2025, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2083: ((2026, 4, 14), [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30]),
        2084: ((2027, 4, 14), [31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30]),
        2085: ((2028, 4, 13), [31, 32, 31, 32, 31, 31, 30, 30, 29, 30, 30, 30]),
        2086: ((2029, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30]),
        2087: ((2030, 4, 14), [31, 31, 32, 31, 31, 31, 30, 30, 29, 30, 30, 30]),
        2088: ((2031, 4, 15), [30, 31, 32, 32, 30, 31, 30, 30, 29, 30, 30, 30]),
        2089: ((2032, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30]),
        2090: ((2033, 4, 14), [31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30])
    ]
    
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
    /// Algorithm: Find approximate BS year, get anchor point, calculate day difference
    static func convertToNepali(year: Int, month: Int, day: Int) -> NepaliDate? {
        // Approximate BS year (AD year + 57)
        let approximateBSYear = year + 57
        
        guard let yearData = calendarData[approximateBSYear] else {
            return nil
        }
        
        // Get anchor point (1st Baisakh) for this BS year
        let anchor = yearData.firstBaisakh
        let anchorADDate = dateFromComponents(year: anchor.year, month: anchor.month, day: anchor.day)
        let targetADDate = dateFromComponents(year: year, month: month, day: day)
        
        guard let anchorDate = anchorADDate, let targetDate = targetADDate else {
            return nil
        }
        
        // Calculate day difference
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: anchorDate, to: targetDate).day ?? 0
        
        // Start from Baisakh 1
        var bsMonth = 1
        var bsDay = 1
        var remainingDays = daysDiff
        
        if remainingDays >= 0 {
            // Forward from anchor
            while remainingDays > 0 {
                let daysInMonth = yearData.daysInMonths[bsMonth - 1]
                let remainingInMonth = daysInMonth - bsDay + 1
                
                if remainingDays >= remainingInMonth {
                    remainingDays -= remainingInMonth
                    bsMonth += 1
                    bsDay = 1
                    
                    if bsMonth > 12 {
                        // Went into next year
                        return convertToNepali(year: year, month: month, day: day - remainingDays)
                    }
                } else {
                    bsDay += remainingDays
                    remainingDays = 0
                }
            }
        } else {
            // Backward from anchor (previous BS year)
            let prevBSYear = approximateBSYear - 1
            guard let prevYearData = calendarData[prevBSYear] else {
                return nil
            }
            
            bsMonth = 12
            bsDay = prevYearData.daysInMonths[11]
            remainingDays = abs(remainingDays)
            
            while remainingDays > 0 {
                if bsDay > remainingDays {
                    bsDay -= remainingDays
                    remainingDays = 0
                } else {
                    remainingDays -= bsDay
                    bsMonth -= 1
                    
                    if bsMonth < 1 {
                        return nil
                    }
                    
                    bsDay = prevYearData.daysInMonths[bsMonth - 1]
                }
            }
            
            return NepaliDate(year: prevBSYear, month: bsMonth, day: bsDay)
        }
        
        return NepaliDate(year: approximateBSYear, month: bsMonth, day: bsDay)
    }
    
    // MARK: - BS to AD Conversion
    
    /// Convert Nepali date to Gregorian date
    static func convertNepaliToGregorian(nepaliDate: NepaliDate) -> Date? {
        guard let yearData = calendarData[nepaliDate.year] else {
            return nil
        }
        
        // Get anchor point (1st Baisakh) for this BS year
        let anchor = yearData.firstBaisakh
        guard let anchorDate = dateFromComponents(year: anchor.year, month: anchor.month, day: anchor.day) else {
            return nil
        }
        
        // Count days from 1st Baisakh to target date
        var dayCount = 0
        
        // Add full months before target month
        for month in 1..<nepaliDate.month {
            dayCount += yearData.daysInMonths[month - 1]
        }
        
        // Add days in target month (minus 1 because we start from day 1)
        dayCount += nepaliDate.day - 1
        
        // Add days to anchor date
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: dayCount, to: anchorDate)
    }
    
    // MARK: - Helper Functions
    
    /// Get current Nepali date
    static func getCurrentNepaliDate() -> NepaliDate? {
        return convertToNepali(gregorianDate: Date())
    }
    
    /// Create date from components
    private static func dateFromComponents(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
