import Adhan
import Foundation
import PrayerKit
import Testing

@Test func noRemindersByDefault() {
    let defaults = emptyDefaults()
    #expect(defaults.reminders == Reminders())
    #expect(makkah.alerts(defaults.reminders, after: makkahTime(2016, 2, 4, 12, 0)).isEmpty)
}

@Test func remindersRoundTrip() {
    let defaults = emptyDefaults()
    var reminders = Reminders()
    reminders[.asr] = 10
    reminders.beforeIqamah = 5
    defaults.reminders = reminders
    #expect(defaults.reminders == reminders)
}

// Makkah on 4 February 2016: Asr at 15:49, Isha at 19:43.
@Test func alertsCoverTheNextTwoDaysInOrder() throws {
    var reminders = Reminders()
    reminders[.fajr] = 0
    reminders[.asr] = 10
    let now = makkahTime(2016, 2, 4, 12, 0)
    let alerts = makkah.alerts(reminders, after: now)
    let asr = try #require(makkah.times(on: now)?.asr)
    let first = try #require(alerts.first)
    #expect(first.prayer == .asr && !first.isIqamah)
    #expect(first.time == asr)
    #expect(first.date == asr.addingTimeInterval(-10 * 60))
    // Today's Asr, then Fajr and Asr on the 5th, then Fajr on the 6th, before 12:00 on the 6th.
    #expect(alerts.map(\.prayer) == [.asr, .fajr, .asr, .fajr])
    #expect(alerts.map(\.date) == alerts.map(\.date).sorted())
}

@Test func afterIshaTheFirstAlertIsTomorrowsFajr() throws {
    var reminders = Reminders()
    reminders[.fajr] = 0
    reminders[.isha] = 0
    let alerts = makkah.alerts(reminders, after: makkahTime(2016, 2, 4, 21, 0))
    #expect(alerts.first?.prayer == .fajr)
    #expect(alerts.first?.time == makkah.times(on: makkahTime(2016, 2, 5, 12, 0))?.fajr)
}

@Test func iqamahReminderIsOnlyForPrayersWithAnIqamah() throws {
    let schedule = makkahWithIqamah(.asr, .afterAdhan(minutes: 20))
    var reminders = Reminders()
    reminders.beforeIqamah = 5
    // Asr's iqamah is at 16:09, so its reminder is at 16:04.
    let alerts = schedule.alerts(reminders, after: makkahTime(2016, 2, 4, 15, 55))
    let first = try #require(alerts.first)
    #expect(first.isIqamah && first.prayer == .asr)
    #expect(first.date == schedule.iqamah(for: .asr, on: makkahTime(2016, 2, 4, 12, 0))?.addingTimeInterval(-5 * 60))
    #expect(alerts.allSatisfy { $0.isIqamah && $0.prayer == .asr })
}

@Test func onlyRemindersAtTheAdhanPlayIt() {
    var reminders = Reminders()
    reminders[.sunrise] = 0
    reminders[.dhuhr] = 0
    reminders[.asr] = 10
    reminders.beforeIqamah = 5
    var schedule = makkah
    schedule.iqamahTimes[.dhuhr] = .afterAdhan(minutes: 15)
    // Two days from 03:00: two Dhuhrs. Not sunrise, Asr ten minutes before, or the iqamah.
    let atAdhan = schedule.alerts(reminders, after: makkahTime(2016, 2, 4, 3, 0)).filter(\.isAtAdhan).map(\.prayer)
    #expect(atAdhan == [.dhuhr, .dhuhr])
}
