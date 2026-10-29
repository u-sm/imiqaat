import Adhan
import Foundation
import PrayerKit
import Testing

/// Makkah on 4 February 2016, where Asr is at 15:49 (see the published timetable test).
func makkahWithIqamah(_ prayer: Prayer, _ iqamah: Iqamah) -> PrayerSchedule {
    var schedule = makkah
    schedule.iqamahTimes[prayer] = iqamah
    return schedule
}

@Test func noIqamahByDefault() {
    #expect(emptyDefaults().iqamahTimes.isEmpty)
    #expect(makkah.iqamah(for: .asr, on: makkahTime(2016, 2, 4, 12, 0)) == nil)
}

@Test func iqamahTimesRoundTrip() {
    let defaults = emptyDefaults()
    var times = IqamahTimes()
    times[.asr] = .afterAdhan(minutes: 20)
    times[.dhuhr] = .fixed(hour: 13, minute: 30)
    defaults.iqamahTimes = times
    #expect(defaults.iqamahTimes == times)
    #expect(defaults.prayerSchedule(deviceCoordinates: makkah.coordinates)?.iqamahTimes == times)
}

@Test func iqamahAfterTheAdhan() throws {
    let schedule = makkahWithIqamah(.asr, .afterAdhan(minutes: 20))
    let day = makkahTime(2016, 2, 4, 12, 0)
    let adhan = try #require(schedule.times(on: day)?.asr)
    #expect(schedule.iqamah(for: .asr, on: day) == adhan.addingTimeInterval(20 * 60))
}

@Test func fixedIqamahIsThatClockTimeInTheSchedulesTimeZone() {
    let schedule = makkahWithIqamah(.asr, .fixed(hour: 16, minute: 15))
    #expect(schedule.iqamah(for: .asr, on: makkahTime(2016, 2, 4, 12, 0)) == makkahTime(2016, 2, 4, 16, 15))
}

@Test func fixedIqamahBeforeTheAdhanIsSkipped() {
    // Asr's adhan is at 15:49, so a 15:30 iqamah can't happen that day.
    let schedule = makkahWithIqamah(.asr, .fixed(hour: 15, minute: 30))
    #expect(schedule.iqamah(for: .asr, on: makkahTime(2016, 2, 4, 12, 0)) == nil)
}

@Test func fixedIqamahKeepsItsClockTimeOnADaylightSavingDay() throws {
    // Clocks in London go forward an hour at 01:00 on 29 March 2026.
    var london = PrayerSchedule(
        coordinates: Coordinates(latitude: 51.5074, longitude: -0.1278),
        parameters: CalculationMethod.muslimWorldLeague.params,
        timeZone: TimeZone(identifier: "Europe/London")!
    )
    london.iqamahTimes[.dhuhr] = .fixed(hour: 13, minute: 30)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = london.timeZone
    let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 29, hour: 12)))
    let iqamah = try #require(london.iqamah(for: .dhuhr, on: day))
    #expect(calendar.dateComponents([.hour, .minute], from: iqamah) == DateComponents(hour: 13, minute: 30))
}

@Test func pendingIqamahIsBetweenTheAdhanAndTheIqamah() throws {
    let schedule = makkahWithIqamah(.asr, .afterAdhan(minutes: 20))
    // Asr's adhan is at 15:49, so its iqamah is at 16:09.
    let pending = try #require(schedule.pendingIqamah(at: makkahTime(2016, 2, 4, 15, 55)))
    #expect(pending.prayer == .asr)
    #expect(pending.time == schedule.iqamah(for: .asr, on: makkahTime(2016, 2, 4, 12, 0)))
    #expect(schedule.pendingIqamah(at: makkahTime(2016, 2, 4, 15, 40)) == nil)
    #expect(schedule.pendingIqamah(at: makkahTime(2016, 2, 4, 16, 30)) == nil)
}

// 4 February 2016 was a Thursday, so 5 February was a Friday.
@Test func jumuahIsDhuhrOnFridayInTheLocationsTimeZone() throws {
    // 21:30 UTC on Thursday is already 00:30 on Friday in Makkah.
    let fridayInMakkah = try #require(ISO8601DateFormatter().date(from: "2016-02-04T21:30:00Z"))
    #expect(makkah.isJumuah(.dhuhr, on: fridayInMakkah))
    #expect(!makkah.isJumuah(.asr, on: fridayInMakkah))
    #expect(!makkah.isJumuah(.dhuhr, on: makkahTime(2016, 2, 4, 23, 30)))
}

@Test func jumuahTimeReplacesDhuhrsIqamahOnFridaysOnly() {
    var schedule = makkahWithIqamah(.dhuhr, .afterAdhan(minutes: 10))
    schedule.iqamahTimes.jumuah = .fixed(hour: 13, minute: 15)
    #expect(schedule.iqamah(for: .dhuhr, on: makkahTime(2016, 2, 5, 9, 0)) == makkahTime(2016, 2, 5, 13, 15))
    let thursday = makkahTime(2016, 2, 4, 9, 0)
    #expect(schedule.iqamah(for: .dhuhr, on: thursday) == schedule.times(on: thursday)?.dhuhr.addingTimeInterval(10 * 60))
}

@Test func khutbahIsOnFridaysOnly() {
    var schedule = makkah
    schedule.iqamahTimes.khutbah = .fixed(hour: 12, minute: 45)
    #expect(schedule.khutbah(on: makkahTime(2016, 2, 5, 9, 0)) == makkahTime(2016, 2, 5, 12, 45))
    #expect(schedule.khutbah(on: makkahTime(2016, 2, 4, 9, 0)) == nil)
}
