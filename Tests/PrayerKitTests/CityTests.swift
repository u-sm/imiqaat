import Adhan
import Foundation
import PrayerKit
import Testing

var london: City {
    City(
        name: "London, United Kingdom",
        coordinates: Coordinates(latitude: 51.5074, longitude: -0.1278),
        timeZone: TimeZone(identifier: "Europe/London")!
    )
}

@Test func noCityAtFirst() {
    #expect(emptyDefaults().city == nil)
}

@Test func cityRoundTrips() {
    let defaults = emptyDefaults()
    defaults.city = london
    #expect(defaults.city == london)
    defaults.city = nil
    #expect(defaults.city == nil)
}

@Test func chosenCityIsUsedInItsTimeZone() throws {
    let defaults = emptyDefaults()
    defaults.city = london
    // The Mac's own location is ignored while a city is chosen.
    let schedule = try #require(defaults.prayerSchedule(deviceCoordinates: makkah.coordinates))
    #expect(schedule.coordinates == london.coordinates)
    #expect(schedule.timeZone == london.timeZone)
}

@Test func withoutACityTheMacsLocationIsUsed() throws {
    let defaults = emptyDefaults()
    let schedule = try #require(defaults.prayerSchedule(deviceCoordinates: makkah.coordinates))
    #expect(schedule.coordinates == makkah.coordinates)
    #expect(schedule.timeZone == .autoupdatingCurrent)
    #expect(defaults.prayerSchedule(deviceCoordinates: nil) == nil)
}
