import Adhan
import Foundation
import PrayerKit
import Testing

@Test func settingsDefaultWhenNothingIsSaved() {
    let parameters = emptyDefaults().calculationParameters
    #expect(parameters.method == .muslimWorldLeague)
    #expect(parameters.madhab == .shafi)
    #expect(parameters.highLatitudeRule == nil)
}

@Test func cardShowsOnLockScreenUntilTurnedOff() {
    let defaults = emptyDefaults()
    #expect(defaults.showOnLockScreen)
    defaults.showOnLockScreen = false
    #expect(!defaults.showOnLockScreen)
}

@Test func cardSitsBottomLeftUntilMoved() {
    let defaults = emptyDefaults()
    #expect(defaults.cardPosition == .bottomLeft && defaults.cardMargin == .medium)
    defaults.cardPosition = .topRight
    defaults.cardMargin = .large
    #expect(defaults.cardPosition == .topRight && defaults.cardMargin == .large)
}

@Test func cardTextIsStandardUntilChanged() {
    let defaults = emptyDefaults()
    #expect(defaults.cardTextSize == .standard)
    defaults.cardTextSize = .extraLarge
    #expect(defaults.cardTextSize == .extraLarge)
}

@Test func cardIsFullUntilChanged() {
    let defaults = emptyDefaults()
    #expect(defaults.cardStyle == .full)
    defaults.cardStyle = .compact
    #expect(defaults.cardStyle == .compact)
}

@Test func menuBarShowsTheTimeUntilChanged() {
    let defaults = emptyDefaults()
    #expect(defaults.menuBarStyle == .time)
    defaults.menuBarStyle = .countdown
    #expect(defaults.menuBarStyle == .countdown)
}

@Test func savedSettingsAreUsed() {
    let defaults = emptyDefaults()
    defaults.calculationMethod = .adhan(.ummAlQura)
    defaults.madhab = .hanafi
    defaults.highLatitudeRule = .seventhOfTheNight
    let parameters = defaults.calculationParameters
    #expect(parameters.method == .ummAlQura)
    #expect(parameters.madhab == .hanafi)
    #expect(parameters.highLatitudeRule == .seventhOfTheNight)
}

@Test func highLatitudeRuleCanGoBackToAutomatic() {
    let defaults = emptyDefaults()
    defaults.highLatitudeRule = .twilightAngle
    defaults.highLatitudeRule = nil
    #expect(defaults.highLatitudeRule == nil)
}

@Test func jakimIsSavedAndUsed() {
    let defaults = emptyDefaults()
    defaults.calculationMethod = .jakim
    #expect(defaults.calculationMethod == .jakim)
    #expect(defaults.calculationParameters.fajrAngle == 18)
}

@Test func noPrayerAdjustmentsByDefault() {
    #expect(emptyDefaults().calculationParameters.adjustments == PrayerAdjustments())
}

@Test func prayerAdjustmentsMoveTheTimes() throws {
    let defaults = emptyDefaults()
    defaults.calculationMethod = .adhan(.ummAlQura)
    let date = makkahTime(2016, 2, 4, 12, 0)
    let before = try #require(PrayerSchedule(coordinates: makkah.coordinates, parameters: defaults.calculationParameters, timeZone: makkah.timeZone).times(on: date))
    defaults.prayerAdjustments = PrayerAdjustments(asr: 5, isha: -3)
    let after = try #require(PrayerSchedule(coordinates: makkah.coordinates, parameters: defaults.calculationParameters, timeZone: makkah.timeZone).times(on: date))
    #expect(after.asr.timeIntervalSince(before.asr) == 5 * 60)
    #expect(after.isha.timeIntervalSince(before.isha) == -3 * 60)
    #expect(after.dhuhr == before.dhuhr)
}

@Test func prayerAdjustmentsAddToJakims() {
    let defaults = emptyDefaults()
    defaults.calculationMethod = .jakim
    defaults.prayerAdjustments = PrayerAdjustments(dhuhr: 3)
    #expect(defaults.calculationParameters.adjustments.dhuhr == PrayerMethod.jakim.params.adjustments.dhuhr + 3)
}
