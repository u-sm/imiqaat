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
