import Foundation
import PrayerKit
import Testing

// From 20 May 2025 (22 Dhu al-Qadah 1446), the next dates cross into 1447. Checked against
// Foundation's Umm al-Qura calendar in Makkah.
@Test func upcomingDatesFollowUmmAlQura() {
    let upcoming = makkah.upcomingIslamicDates(from: makkahTime(2025, 5, 20, 9, 0))
    let expected: [(IslamicDate, Int, Date)] = [
        (.arafah, 16, makkahTime(2025, 6, 5, 12, 0)),
        (.eidAlAdha, 17, makkahTime(2025, 6, 6, 12, 0)),
        (.newYear, 37, makkahTime(2025, 6, 26, 12, 0)),
        (.ashura, 46, makkahTime(2025, 7, 5, 12, 0)),
        (.ramadan, 274, makkahTime(2026, 2, 18, 12, 0)),
        (.eidAlFitr, 304, makkahTime(2026, 3, 20, 12, 0)),
    ]
    #expect(upcoming.map(\.date) == expected.map(\.0))
    #expect(upcoming.map(\.inDays) == expected.map(\.1))
    #expect(upcoming.map(\.day) == expected.map(\.2))
}

@Test func aDateIsTodayOnTheDayItself() {
    // After Maghrib on Eid al-Adha the Hijri date has moved on, but the day is still Eid.
    let first = makkah.upcomingIslamicDates(from: makkahTime(2025, 6, 6, 21, 0)).first
    #expect(first?.date == .eidAlAdha)
    #expect(first?.inDays == 0)
}

@Test func namesTheDateOfAHijriDay() {
    #expect(IslamicDate(makkah.hijriDate(at: makkahTime(2025, 6, 5, 12, 0))) == .arafah)
    #expect(IslamicDate(makkah.hijriDate(at: makkahTime(2025, 6, 5, 20, 0))) == .eidAlAdha)
    #expect(IslamicDate(makkah.hijriDate(at: makkahTime(2025, 6, 7, 12, 0))) == nil)
}
