import Foundation

enum AppTimeZone {
    /// Icy Strait Point / Hoonah, Alaska.
    static let alaska = TimeZone(identifier: "America/Juneau") ?? .current

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = alaska
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }
}

enum Season {
    static let year = 2027
    static let capacityPerHour = 6
    static let openHour = 8
    static let closeHour = 19
    static let firstSlotHour = 8
    static let lastSlotHour = 18

    static var start: Date {
        date(year: year, month: 5, day: 1, hour: 0, minute: 0)
    }

    static var endInclusive: Date {
        date(year: year, month: 9, day: 30, hour: 23, minute: 59)
    }

    static var slotHours: [Int] {
        Array(firstSlotHour...lastSlotHour)
    }

    static func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = AppTimeZone.alaska
        return AppTimeZone.calendar.date(from: components) ?? Date()
    }

    static func isInSeason(_ date: Date) -> Bool {
        let day = AppTimeZone.calendar.startOfDay(for: date)
        let startDay = AppTimeZone.calendar.startOfDay(for: start)
        let endDay = AppTimeZone.calendar.startOfDay(for: endInclusive)
        return day >= startDay && day <= endDay
    }

    static func isDuringHours(_ date: Date) -> Bool {
        let hour = AppTimeZone.calendar.component(.hour, from: date)
        let minute = AppTimeZone.calendar.component(.minute, from: date)
        if hour < openHour { return false }
        if hour > lastSlotHour { return false }
        if hour == closeHour && minute > 0 { return false }
        return hour < closeHour
    }

    static func slotStart(on day: Date, hour: Int) -> Date {
        let parts = AppTimeZone.calendar.dateComponents([.year, .month, .day], from: day)
        return date(year: parts.year ?? year, month: parts.month ?? 5, day: parts.day ?? 1, hour: hour, minute: 0)
    }

    static func slotEnd(on day: Date, hour: Int) -> Date {
        slotStart(on: day, hour: hour).addingTimeInterval(3600)
    }

    static func label(forHour hour: Int) -> String {
        let start = hour
        let end = hour + 1
        return "\(clock(start))–\(clock(end))"
    }

    static func clock(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 || hour == 24 ? "am" : "pm"
        if hour == 12 { return "12pm" }
        if hour == 0 { return "12am" }
        return "\(h)\(suffix)"
    }

    static func months() -> [Date] {
        [5, 6, 7, 8, 9].compactMap { month in
            date(year: year, month: month, day: 1)
        }
    }
}

struct HourSlot: Identifiable, Hashable {
    let hour: Int

    var id: Int { hour }

    var label: String { Season.label(forHour: hour) }
}
