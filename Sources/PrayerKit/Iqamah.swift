import Adhan
import Foundation

/// When the congregation prays, relative to the adhan or at a fixed clock time.
public enum Iqamah: Codable, Equatable, Hashable {
    case afterAdhan(minutes: Int)
    /// In the schedule's time zone. Skipped on days when it falls before the adhan.
    case fixed(hour: Int, minute: Int)
}

/// The iqamah for each prayer that has one.
public struct IqamahTimes: Codable, Equatable {
    // Keyed by the prayer's name, because adhan-swift's Prayer isn't Codable.
    private var byPrayer: [String: Iqamah] = [:]

    public init() {}

    public subscript(prayer: Prayer) -> Iqamah? {
        get { byPrayer["\(prayer)"] }
        set { byPrayer["\(prayer)"] = newValue }
    }

    public var isEmpty: Bool { byPrayer.isEmpty }
}

extension UserDefaults {
    /// None by default.
    public var iqamahTimes: IqamahTimes {
        get { data(forKey: "iqamahTimes").flatMap { try? JSONDecoder().decode(IqamahTimes.self, from: $0) } ?? IqamahTimes() }
        set { set(try? JSONEncoder().encode(newValue), forKey: "iqamahTimes") }
    }
}

extension PrayerSchedule {
    /// The iqamah for `prayer` on the day containing `date`, or nil if it has none that day.
    public func iqamah(for prayer: Prayer, on date: Date) -> Date? {
        guard let setting = iqamahTimes[prayer], let adhan = times(on: date)?.time(for: prayer) else { return nil }
        switch setting {
        case let .afterAdhan(minutes):
            return adhan.addingTimeInterval(Double(minutes) * 60)
        case let .fixed(hour, minute):
            var day = calendar.dateComponents([.year, .month, .day], from: date)
            day.hour = hour
            day.minute = minute
            guard let fixed = calendar.date(from: day), fixed >= adhan else { return nil }
            return fixed
        }
    }

    /// The prayer whose adhan has passed but whose iqamah is still to come, with the iqamah time.
    public func pendingIqamah(at date: Date) -> (prayer: Prayer, time: Date)? {
        guard
            let prayer = times(on: date)?.currentPrayer(at: date),
            let iqamah = iqamah(for: prayer, on: date),
            date < iqamah
        else { return nil }
        return (prayer, iqamah)
    }
}
