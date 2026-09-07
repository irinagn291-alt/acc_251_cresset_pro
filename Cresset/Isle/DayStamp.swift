import Foundation

/// Role: Isle. Session day as Int YYYYMMDD from Calendar.startOfDay. Never a Date dictionary key.
struct DayStamp: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> DayStamp {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return DayStamp(rawValue: year * 10_000 + month * 100 + day)
    }

    static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
