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
