import Adhan
import Foundation

/// A place chosen by name in Settings, used instead of the Mac's location.
public struct City: Codable, Equatable {
    /// For display, for example "London, United Kingdom".
    public var name: String
    public var coordinates: Coordinates
    public var timeZone: TimeZone

    public init(name: String, coordinates: Coordinates, timeZone: TimeZone) {
        self.name = name
        self.coordinates = coordinates
        self.timeZone = timeZone
    }
}

extension UserDefaults {
    /// The chosen city, or nil to use the Mac's location.
    public var city: City? {
        get { data(forKey: "city").flatMap { try? JSONDecoder().decode(City.self, from: $0) } }
        set { set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: "city") }
    }

    /// The schedule to show: the chosen city's, in its time zone, or else the Mac's, in the
    /// Mac's time zone. Nil when there's no city and no usable location.
    public func prayerSchedule(deviceCoordinates: Coordinates?) -> PrayerSchedule? {
        if let city {
            return PrayerSchedule(coordinates: city.coordinates, parameters: calculationParameters, timeZone: city.timeZone, iqamahTimes: iqamahTimes)
        }
        return deviceCoordinates.map { PrayerSchedule(coordinates: $0, parameters: calculationParameters, timeZone: .autoupdatingCurrent, iqamahTimes: iqamahTimes) }
    }
}
