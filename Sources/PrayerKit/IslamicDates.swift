import Foundation

/// A yearly date in the Hijri calendar.
public enum IslamicDate: CaseIterable {
    case ramadan, eidAlFitr, arafah, eidAlAdha, newYear, ashura

    public var name: String {
        switch self {
        case .ramadan: "Start of Ramadan"
        case .eidAlFitr: "Eid al-Fitr"
        case .arafah: "Day of Arafah"
        case .eidAlAdha: "Eid al-Adha"
        case .newYear: "Islamic New Year"
        case .ashura: "Ashura"
        }
    }

    var month: Int {
        switch self {
        case .ramadan: 9
        case .eidAlFitr: 10
        case .arafah, .eidAlAdha: 12
        case .newYear, .ashura: 1
        }
    }

    var day: Int {
        switch self {
        case .ramadan, .eidAlFitr, .newYear: 1
        case .arafah: 9
        case .eidAlAdha, .ashura: 10
        }
    }

    /// The date falling on a Hijri date, as `PrayerSchedule.hijriDate(at:)` gives it.
    public init?(_ hijri: DateComponents) {
        guard let date = Self.allCases.first(where: { $0.month == hijri.month && $0.day == hijri.day }) else { return nil }
        self = date
    }
}

extension PrayerSchedule {
    /// When each date next falls, soonest first, counting the day containing `date` as day 0.
    /// A day's Hijri date is `hijriDate(at:)` at its midday, so any Hijri adjustment applies here too.
    public func upcomingIslamicDates(from date: Date) -> [(date: IslamicDate, inDays: Int, day: Date)] {
        var upcoming: [(date: IslamicDate, inDays: Int, day: Date)] = []
        // A Hijri year is at most 355 days, so every date falls within this many.
        for offset in 0..<356 {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: date),
                let midday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day),
                let islamicDate = IslamicDate(hijriDate(at: midday)),
                !upcoming.contains(where: { $0.date == islamicDate })
            else { continue }
            upcoming.append((islamicDate, offset, midday))
        }
        return upcoming
    }
}
