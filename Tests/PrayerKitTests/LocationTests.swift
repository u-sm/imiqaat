import Adhan
import Foundation
import PrayerKit
import Testing

/// An empty defaults domain for one test, so tests never touch the app's own cache.
func emptyDefaults(for test: String = #function) -> UserDefaults {
    let name = "PrayerKitTests.\(test)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@Test func noCachedCoordinatesAtFirst() {
    #expect(emptyDefaults().cachedCoordinates == nil)
}

@Test func cachedCoordinatesRoundTrip() {
    let defaults = emptyDefaults()
    let london = Coordinates(latitude: 51.5074, longitude: -0.1278)
    defaults.cachedCoordinates = london
    #expect(defaults.cachedCoordinates == london)
}
