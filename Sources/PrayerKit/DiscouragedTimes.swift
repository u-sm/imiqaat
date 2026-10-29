import Foundation

/// How long each time when voluntary prayer is discouraged lasts, in minutes. The three times are
/// from Sahih Muslim 831; their lengths aren't, and scholars differ on them (see docs/ROADMAP.md).
public struct DiscouragedTimes: Codable, Equatable {
    /// From sunrise, while the sun rises.
    public var afterSunrise = 15
    /// Before Dhuhr, while the sun is at its zenith.
    public var beforeDhuhr = 10
    /// Before Maghrib, while the sun sets.
    public var beforeMaghrib = 15

    public init() {}
}

extension UserDefaults {
    /// Nil, the default, when the card doesn't mark them.
    public var discouragedTimes: DiscouragedTimes? {
        get { data(forKey: "discouragedTimes").flatMap { try? JSONDecoder().decode(DiscouragedTimes.self, from: $0) } }
        set { set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: "discouragedTimes") }
    }
}

extension PrayerSchedule {
    /// When the discouraged time containing `date` ends, or nil outside them.
    public func discouragedTimeEnd(at date: Date, _ lengths: DiscouragedTimes) -> Date? {
        guard let today = times(on: date) else { return nil }
        let minutes = { (count: Int) in Double(count) * 60 }
        let windows = [
            (today.sunrise, today.sunrise.addingTimeInterval(minutes(lengths.afterSunrise))),
            (today.dhuhr.addingTimeInterval(-minutes(lengths.beforeDhuhr)), today.dhuhr),
            (today.maghrib.addingTimeInterval(-minutes(lengths.beforeMaghrib)), today.maghrib),
        ]
        return windows.first { $0.0 <= date && date < $0.1 }?.1
    }
}
