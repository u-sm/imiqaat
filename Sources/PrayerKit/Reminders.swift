import Adhan
import Foundation

/// Which prayers to be notified about, and how early.
public struct Reminders: Codable, Equatable {
    // Keyed by the prayer's name, like IqamahTimes, because adhan-swift's Prayer isn't Codable.
    private var byPrayer: [String: Int] = [:]

    public init() {}

    /// Minutes before the adhan to notify, 0 for at the adhan, or nil for no reminder.
    public subscript(prayer: Prayer) -> Int? {
        get { byPrayer["\(prayer)"] }
        set { byPrayer["\(prayer)"] = newValue }
    }

    /// Minutes before the iqamah to notify, for prayers that have one, or nil for no reminder.
    public var beforeIqamah: Int? {
        get { byPrayer["iqamah"] }
        set { byPrayer["iqamah"] = newValue }
    }
}

extension UserDefaults {
    /// None by default.
    public var reminders: Reminders {
        get { data(forKey: "reminders").flatMap { try? JSONDecoder().decode(Reminders.self, from: $0) } ?? Reminders() }
        set { set(try? JSONEncoder().encode(newValue), forKey: "reminders") }
    }
}

/// One notification to send.
public struct PrayerAlert: Equatable {
    public var prayer: Prayer
    /// True for the iqamah reminder, false for the adhan's.
    public var isIqamah: Bool
    /// When the adhan or iqamah is.
    public var time: Date
    /// When to notify: `time`, or some minutes before it.
    public var date: Date

    /// Stable for the same reminder, so an unchanged schedule needn't be sent again.
    public var id: String { "\(prayer)-\(isIqamah ? "iqamah" : "adhan")-\(Int(date.timeIntervalSince1970))" }
}

extension PrayerSchedule {
    /// The notifications due after `date` and within the next two days, in order. Two days keeps
    /// well under the system's limit on pending notifications; the app reschedules as days pass.
    public func alerts(_ reminders: Reminders, after date: Date) -> [PrayerAlert] {
        let end = date.addingTimeInterval(2 * 24 * 60 * 60)
        var alerts: [PrayerAlert] = []
        for offset in 0...2 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date), let times = times(on: day) else { continue }
            for prayer in Prayer.allCases {
                if let minutes = reminders[prayer] {
                    let time = times.time(for: prayer)
                    alerts.append(PrayerAlert(prayer: prayer, isIqamah: false, time: time, date: time.addingTimeInterval(-Double(minutes) * 60)))
                }
                if let minutes = reminders.beforeIqamah, let time = iqamah(for: prayer, on: day) {
                    alerts.append(PrayerAlert(prayer: prayer, isIqamah: true, time: time, date: time.addingTimeInterval(-Double(minutes) * 60)))
                }
            }
        }
        return alerts.filter { $0.date > date && $0.date <= end }.sorted { $0.date < $1.date }
    }
}
