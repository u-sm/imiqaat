import Adhan
import Foundation
import PrayerKit
import Testing
import WidgetUI

// Friday 5 February 2016 in Makkah, with the khutbah at 12:45 and Jumu'ah at 13:15.
@Test func cardCountsDownToTheKhutbahThenTheIqamahThenTheNextAdhan() throws {
    var schedule = makkahWithIqamah(.dhuhr, .afterAdhan(minutes: 10))
    schedule.iqamahTimes.khutbah = .fixed(hour: 12, minute: 45)
    schedule.iqamahTimes.jumuah = .fixed(hour: 13, minute: 15)
    let today = try #require(schedule.times(on: makkahTime(2016, 2, 5, 12, 0)))

    func expect(_ hour: Int, _ minute: Int, _ label: String, _ time: Date, _ row: Prayer?) throws {
        let countdown = try #require(schedule.countdown(at: makkahTime(2016, 2, 5, hour, minute)))
        #expect(countdown.label == label, "\(hour):\(minute)")
        #expect(countdown.time == time, "\(hour):\(minute)")
        #expect(countdown.row == row, "\(hour):\(minute)")
    }
    try expect(12, 0, "Jumu'ah", today.dhuhr, .dhuhr)
    try expect(12, 40, "Khutbah", makkahTime(2016, 2, 5, 12, 45), .dhuhr)
    try expect(13, 0, "Jumu'ah iqamah", makkahTime(2016, 2, 5, 13, 15), .dhuhr)
    try expect(13, 30, "Asr", today.asr, .asr)
    // After Isha the next is tomorrow's Fajr, which isn't a row on today's card.
    let tomorrow = try #require(schedule.times(on: makkahTime(2016, 2, 6, 12, 0)))
    try expect(21, 0, "Fajr", tomorrow.fajr, nil)
}
