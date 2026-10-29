import Adhan
import Foundation

/// Prayer times for one place, worked out in that place's time zone.
public struct PrayerSchedule {
    public var coordinates: Coordinates
    public var parameters: CalculationParameters
    public var timeZone: TimeZone
    public var iqamahTimes: IqamahTimes

    public init(coordinates: Coordinates, parameters: CalculationParameters, timeZone: TimeZone, iqamahTimes: IqamahTimes = IqamahTimes()) {
        self.coordinates = coordinates
        self.parameters = parameters
        self.timeZone = timeZone
        self.iqamahTimes = iqamahTimes
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// The times for the day containing `date`. The day is taken in the location's
    /// time zone, not the Mac's. Nil if adhan-swift can't calculate them.
    public func times(on date: Date) -> PrayerTimes? {
        PrayerTimes(
            coordinates: coordinates,
            date: calendar.dateComponents([.year, .month, .day], from: date),
            calculationParameters: parameters
        )
    }

    /// The next time after `date`: one of the five prayers, or sunrise, which ends
    /// Fajr's time. After Isha it is tomorrow's Fajr.
    public func next(after date: Date) -> (prayer: Prayer, time: Date)? {
        guard let today = times(on: date) else { return nil }
        if let prayer = today.nextPrayer(at: date) {
            return (prayer, today.time(for: prayer))
        }
        guard
            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date),
            let tomorrow = times(on: tomorrowDate)
        else { return nil }
        return (.fajr, tomorrow.fajr)
    }

    /// The Umm al-Qura Hijri date. The Islamic day begins at Maghrib, so from Maghrib
    /// onwards this is the next day's date.
    public func hijriDate(at date: Date) -> DateComponents {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        let afterMaghrib = times(on: date).map { date >= $0.maghrib } ?? false
        let day = afterMaghrib ? hijri.date(byAdding: .day, value: 1, to: date) ?? date : date
        return hijri.dateComponents([.year, .month, .day], from: day)
    }
}
