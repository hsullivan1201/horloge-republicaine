import Foundation

struct RepublicanDate {
    let year: Int        // An I = 1792-93
    let month: Int       // 0-11, or 12 for the complementary days
    let day: Int         // 1-30 (1-6 during the complementary days)
    let isLeapYear: Bool // true when the year gets a 6th complementary day
    let yearStart: Date  // Gregorian date of 1 Vendémiaire for this year

    var isComplementary: Bool { month == 12 }

    var decadeDayName: String {
        RepublicanData.decadeDays[(day - 1) % 10]
    }

    var ruralDayName: String? {
        isComplementary ? nil : RepublicanData.ruralDays[month * 30 + (day - 1)]
    }
}

struct DecimalTime {
    let hours: Int    // 0-9
    let minutes: Int  // 0-99
    let seconds: Int  // 0-99
    let dayFraction: Double
}

enum RepublicanCalendar {

    // Each Republican year is anchored to September 22, the Gregorian date of
    // the original 1 Vendémiaire An I (and still where the autumn equinox
    // falls, give or take a day). Anchoring to the Gregorian date keeps the
    // math simple and self-consistent: years spanning a February 29 naturally
    // get a 6th complementary day.
    static func date(from date: Date, calendar: Calendar = .current) -> RepublicanDate {
        let today = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: date)

        var anchorYear = year
        if let anchor = anniversary(of: year, calendar: calendar), today < anchor {
            anchorYear = year - 1
        }
        let yearStart = anniversary(of: anchorYear, calendar: calendar)!
        let nextYearStart = anniversary(of: anchorYear + 1, calendar: calendar)!

        let dayOfYear = calendar.dateComponents([.day], from: yearStart, to: today).day!
        let yearLength = calendar.dateComponents([.day], from: yearStart, to: nextYearStart).day!

        return RepublicanDate(
            year: anchorYear - 1791,
            month: min(dayOfYear / 30, 12),
            day: dayOfYear < 360 ? dayOfYear % 30 + 1 : dayOfYear - 359,
            isLeapYear: yearLength == 366,
            yearStart: yearStart
        )
    }

    // 10 hours per day, 100 minutes per hour, 100 seconds per minute.
    static func decimalTime(for date: Date, calendar: Calendar = .current) -> DecimalTime {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let fraction = date.timeIntervalSince(start) / end.timeIntervalSince(start)
        let total = min(Int(fraction * 100_000), 99_999)
        return DecimalTime(
            hours: total / 10_000,
            minutes: (total / 100) % 100,
            seconds: total % 100,
            dayFraction: fraction
        )
    }

    static func roman(_ number: Int) -> String {
        let values = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
        ]
        var n = number
        var result = ""
        for (value, numeral) in values {
            while n >= value {
                result += numeral
                n -= value
            }
        }
        return result
    }

    private static func anniversary(of year: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: 9, day: 22))
    }
}
