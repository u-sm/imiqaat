import Adhan
import Foundation
import PrayerKit
import Testing
import WidgetUI

// Ramadan 1437 ran from 6 June to 5 July 2016 in Makkah.

@Test func ummAlQurasIshaIsTwoHoursAfterMaghribInRamadan() throws {
    let before = try #require(makkah.times(on: makkahTime(2016, 6, 5, 12, 0)))
    let during = try #require(makkah.times(on: makkahTime(2016, 6, 6, 12, 0)))
    let after = try #require(makkah.times(on: makkahTime(2016, 7, 6, 12, 0)))
    #expect(before.isha.timeIntervalSince(before.maghrib) == 90 * 60)
    #expect(during.isha.timeIntervalSince(during.maghrib) == 120 * 60)
    #expect(after.isha.timeIntervalSince(after.maghrib) == 90 * 60)
}

@Test func otherMethodsKeepTheirIshaInRamadan() throws {
    var schedule = makkah
    schedule.parameters = CalculationMethod.muslimWorldLeague.params
    var outside = schedule
    outside.parameters.method = .other
    // The same angles, but not Umm al-Qura, so no extra 30 minutes.
    #expect(schedule.times(on: makkahTime(2016, 6, 6, 12, 0))?.isha == outside.times(on: makkahTime(2016, 6, 6, 12, 0))?.isha)
}

@Test func ramadanCountsDownToIftarThenTheEndOfSuhoor() throws {
    let today = try #require(makkah.times(on: makkahTime(2016, 6, 10, 12, 0)))
    let tomorrow = try #require(makkah.times(on: makkahTime(2016, 6, 11, 12, 0)))
    // From Fajr until Maghrib, iftar.
    let noon = makkahTime(2016, 6, 10, 12, 0)
    #expect(makkah.fastCountdown(at: noon, imsakMinutes: 0) == "Iftar in \(minutes(from: noon, to: today.maghrib))")
    // From Maghrib, the end of tomorrow's suhoor: at Fajr, or the imsak margin before it.
    let night = makkahTime(2016, 6, 10, 22, 0)
    #expect(makkah.fastCountdown(at: night, imsakMinutes: 0) == "Suhoor ends in \(minutes(from: night, to: tomorrow.fajr))")
    #expect(makkah.fastCountdown(at: night, imsakMinutes: 10) == "Suhoor ends in \(minutes(from: night, to: tomorrow.fajr.addingTimeInterval(-600)))")
    // Between the end of suhoor and Fajr, nothing.
    #expect(makkah.fastCountdown(at: tomorrow.fajr.addingTimeInterval(-300), imsakMinutes: 10) == nil)
}

@Test func ramadanModeFollowsTheHijriDate() throws {
    // The first suhoor countdown starts at Maghrib on the eve of 1 Ramadan; the last iftar is on 30 Ramadan.
    #expect(makkah.fastCountdown(at: makkahTime(2016, 6, 5, 12, 0), imsakMinutes: 0) == nil)
    #expect(makkah.fastCountdown(at: makkahTime(2016, 6, 5, 22, 0), imsakMinutes: 0)?.hasPrefix("Suhoor ends") == true)
    #expect(makkah.fastCountdown(at: makkahTime(2016, 7, 5, 12, 0), imsakMinutes: 0)?.hasPrefix("Iftar") == true)
    #expect(makkah.fastCountdown(at: makkahTime(2016, 7, 5, 22, 0), imsakMinutes: 0) == nil)
}

@Test func ramadanModeIsOnAndSuhoorEndsAtFajrUntilChanged() {
    let defaults = emptyDefaults()
    #expect(defaults.ramadanMode && defaults.imsakMinutes == 0)
    defaults.ramadanMode = false
    defaults.imsakMinutes = 10
    #expect(!defaults.ramadanMode && defaults.imsakMinutes == 10)
}

/// The card's narrow form of the time left, rounded up to the minute.
private func minutes(from date: Date, to time: Date) -> String {
    Duration.seconds((time.timeIntervalSince(date) / 60).rounded(.up) * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
}
