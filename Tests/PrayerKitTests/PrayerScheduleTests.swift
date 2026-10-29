import Adhan
import Foundation
import PrayerKit
import Testing

var makkah: PrayerSchedule {
    PrayerSchedule(
        coordinates: Coordinates(latitude: 21.427009, longitude: 39.828685),
        parameters: CalculationMethod.ummAlQura.params,
        timeZone: TimeZone(identifier: "Asia/Riyadh")!
    )
}

/// A moment in Makkah's local time.
func makkahTime(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = makkah.timeZone
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

// Umm al-Qura's published timetable for Makkah on 4 February 2016 (25 Rabi' al-Akhir 1437),
// from ummulqura.org.sa via adhan-swift's test data. The source allows ±1 minute.
@Test func matchesPublishedUmmAlQuraTimetable() throws {
    let times = try #require(makkah.times(on: makkahTime(2016, 2, 4, 12, 0)))
    let published: [(Prayer, Int, Int)] = [
        (.fajr, 5, 39), (.sunrise, 6, 57), (.dhuhr, 12, 35),
        (.asr, 15, 49), (.maghrib, 18, 13), (.isha, 19, 43),
    ]
    for (prayer, hour, minute) in published {
        let difference = abs(times.time(for: prayer).timeIntervalSince(makkahTime(2016, 2, 4, hour, minute)))
        #expect(difference <= 60, "\(prayer)")
    }
}

@Test func usesTheLocationsCalendarDay() throws {
    // 22:30 UTC on 3 February is already 4 February in Makkah.
    let date = try #require(ISO8601DateFormatter().date(from: "2016-02-03T22:30:00Z"))
    let times = try #require(makkah.times(on: date))
    #expect(times.date.day == 4)
}

@Test func nextPrayerIsLaterTheSameDay() {
    #expect(makkah.next(after: makkahTime(2016, 2, 4, 13, 0))?.prayer == .asr)
}

@Test func nextPrayerAfterIshaIsTomorrowsFajr() throws {
    let next = try #require(makkah.next(after: makkahTime(2016, 2, 4, 21, 0)))
    #expect(next.prayer == .fajr)
    #expect(next.time == makkah.times(on: makkahTime(2016, 2, 5, 12, 0))?.fajr)
}

@Test func sunnahTimesMatchAdhan() throws {
    let night = try #require(makkah.sunnahTimes(at: makkahTime(2016, 2, 4, 21, 0)))
    let expected = try #require(makkah.times(on: makkahTime(2016, 2, 4, 12, 0)).flatMap(SunnahTimes.init(from:)))
    #expect(night.middleOfTheNight == expected.middleOfTheNight)
    #expect(night.lastThirdOfTheNight == expected.lastThirdOfTheNight)
    // Between Maghrib on the 4th and Fajr on the 5th.
    #expect(night.middleOfTheNight > makkahTime(2016, 2, 4, 23, 0) && night.middleOfTheNight < makkahTime(2016, 2, 5, 0, 30))
    #expect(night.lastThirdOfTheNight > makkahTime(2016, 2, 5, 1, 0) && night.lastThirdOfTheNight < makkahTime(2016, 2, 5, 2, 0))
}

@Test func sunnahTimesAreTonightsAcrossMidnight() {
    let tonight = makkah.sunnahTimes(at: makkahTime(2016, 2, 4, 23, 0))?.lastThirdOfTheNight
    // After midnight but before Fajr, still the night that began on the 4th.
    #expect(makkah.sunnahTimes(at: makkahTime(2016, 2, 5, 1, 0))?.lastThirdOfTheNight == tonight)
    // After Fajr, the coming night.
    #expect(makkah.sunnahTimes(at: makkahTime(2016, 2, 5, 6, 0))?.lastThirdOfTheNight
        == makkah.times(on: makkahTime(2016, 2, 5, 12, 0)).flatMap(SunnahTimes.init(from:))?.lastThirdOfTheNight)
}

@Test func hijriDateMatchesPublishedCalendar() {
    let hijri = makkah.hijriDate(at: makkahTime(2016, 2, 4, 12, 0))
    #expect([hijri.year, hijri.month, hijri.day] == [1437, 4, 25])
}

@Test func hijriDateAdvancesAtMaghrib() {
    #expect(makkah.hijriDate(at: makkahTime(2016, 2, 4, 19, 0)).day == 26)
}

// e-Solat's published timetable for zone WLY01 (Kuala Lumpur) on 29 October 2026. JAKIM's zone
// reference point isn't published, so this uses the city centre and allows ±2 minutes.
@Test func jakimMatchesPublishedESolatTimetable() throws {
    let kualaLumpur = PrayerSchedule(
        coordinates: Coordinates(latitude: 3.1390, longitude: 101.6869),
        parameters: PrayerMethod.jakim.params,
        timeZone: TimeZone(identifier: "Asia/Kuala_Lumpur")!
    )
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = kualaLumpur.timeZone
    func time(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: hour, minute: minute))!
    }
    let times = try #require(kualaLumpur.times(on: time(12, 0)))
    let published: [(Prayer, Int, Int)] = [
        (.fajr, 5, 48), (.sunrise, 6, 56), (.dhuhr, 13, 0),
        (.asr, 16, 19), (.maghrib, 18, 59), (.isha, 20, 9),
    ]
    for (prayer, hour, minute) in published {
        let difference = abs(times.time(for: prayer).timeIntervalSince(time(hour, minute)))
        #expect(difference <= 120, "\(prayer)")
    }
}

@Test func clockUsesTheSchedulesTimeZoneNotTheMacs() throws {
    // 03:00 in London is 12:00 in Tokyo, whatever time zone the Mac is in.
    let moment = try #require(ISO8601DateFormatter().date(from: "2026-01-15T03:00:00Z"))
    func schedule(_ zone: String) -> PrayerSchedule {
        PrayerSchedule(coordinates: makkah.coordinates, parameters: makkah.parameters, timeZone: TimeZone(identifier: zone)!)
    }
    // The format follows the Mac's 12- or 24-hour setting, so check the hour only.
    let london = schedule("Europe/London").clock(moment), tokyo = schedule("Asia/Tokyo").clock(moment)
    #expect(london.contains("3") && !london.contains("12"), "\(london)")
    #expect(tokyo.contains("12"), "\(tokyo)")
}
