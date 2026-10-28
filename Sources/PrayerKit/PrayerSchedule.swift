import Adhan
import Foundation

/// Prayer times for one place, worked out in that place's time zone.
public struct PrayerSchedule {
    public var coordinates: Coordinates
    public var parameters: CalculationParameters
    public var timeZone: TimeZone

    public init(coordinates: Coordinates, parameters: CalculationParameters, timeZone: TimeZone) {
        self.coordinates = coordinates
        self.parameters = parameters
        self.timeZone = timeZone
    }

    private var calendar: Calendar {
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
}
