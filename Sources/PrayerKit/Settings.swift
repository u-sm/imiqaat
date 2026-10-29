import Adhan
import Foundation

/// A calculation method: one of adhan-swift's, or JAKIM, which adhan-swift doesn't have.
public enum PrayerMethod: Hashable {
    case adhan(CalculationMethod)
    /// Malaysia's JAKIM, as published on e-Solat.
    case jakim

    /// The choices offered to the user. adhan-swift's `.other` is a blank template, not a method.
    public static var allCases: [PrayerMethod] {
        CalculationMethod.allCases.filter { $0 != .other }.map(PrayerMethod.adhan) + [.jakim]
    }

    public var params: CalculationParameters {
        switch self {
        case let .adhan(method):
            return method.params
        case .jakim:
            // Subuh at 18° since the 2019 Muzakarah decision. The adjustments are JAKIM's
            // ihtiyati, fitted to e-Solat's 2026 timetables for four zones. adhan-swift keeps
            // methodAdjustments internal, so they use `adjustments`, which the user's offsets add to.
            var params = CalculationMethod.other.params
            params.fajrAngle = 18
            params.ishaAngle = 18
            params.adjustments = PrayerAdjustments(fajr: 1, sunrise: -2, dhuhr: 2, asr: 1, maghrib: 1, isha: 1)
            params.rounding = .up
            return params
        }
    }
}

/// How much the Lock Screen card shows: today's times, or only what's next.
public enum CardStyle: String, CaseIterable {
    case full, compact
}

/// What the menu-bar item shows beside its symbol.
public enum MenuBarStyle: String, CaseIterable {
    case time, countdown, iconOnly
}

extension UserDefaults {
    /// Defaults to Muslim World League. Stored as adhan-swift's raw value, or "jakim".
    public var calculationMethod: PrayerMethod {
        get {
            let stored = string(forKey: "calculationMethod")
            if stored == "jakim" { return .jakim }
            return .adhan(stored.flatMap(CalculationMethod.init) ?? .muslimWorldLeague)
        }
        set {
            switch newValue {
            case let .adhan(method): set(method.rawValue, forKey: "calculationMethod")
            case .jakim: set("jakim", forKey: "calculationMethod")
            }
        }
    }

    /// The Asr method. Defaults to the standard (Shafi'i) one.
    public var madhab: Madhab {
        get { Madhab(rawValue: integer(forKey: "madhab")) ?? .shafi }
        set { set(newValue.rawValue, forKey: "madhab") }
    }

    /// Nil means automatic: adhan-swift picks the rule recommended for the location.
    public var highLatitudeRule: HighLatitudeRule? {
        get { string(forKey: "highLatitudeRule").flatMap(HighLatitudeRule.init) }
        set { set(newValue?.rawValue, forKey: "highLatitudeRule") }
    }

    /// Whether the card shows on the Lock Screen. Defaults to true.
    public var showOnLockScreen: Bool {
        get { object(forKey: "showOnLockScreen") as? Bool ?? true }
        set { set(newValue, forKey: "showOnLockScreen") }
    }

    /// Defaults to the full card.
    public var cardStyle: CardStyle {
        get { string(forKey: "cardStyle").flatMap(CardStyle.init) ?? .full }
        set { set(newValue.rawValue, forKey: "cardStyle") }
    }

    /// Defaults to the next prayer's time.
    public var menuBarStyle: MenuBarStyle {
        get { string(forKey: "menuBarStyle").flatMap(MenuBarStyle.init) ?? .time }
        set { set(newValue.rawValue, forKey: "menuBarStyle") }
    }

    /// The user's offsets in minutes, to match a local mosque's timetable. Defaults to none.
    public var prayerAdjustments: PrayerAdjustments {
        get { data(forKey: "prayerAdjustments").flatMap { try? JSONDecoder().decode(PrayerAdjustments.self, from: $0) } ?? PrayerAdjustments() }
        set { set(try? JSONEncoder().encode(newValue), forKey: "prayerAdjustments") }
    }

    /// The saved choices, combined into the parameters adhan-swift calculates with.
    public var calculationParameters: CalculationParameters {
        var parameters = calculationMethod.params
        parameters.madhab = madhab
        parameters.highLatitudeRule = highLatitudeRule
        // Added to the method's own adjustments rather than replacing them: JAKIM has some.
        let user = prayerAdjustments
        parameters.adjustments.fajr += user.fajr
        parameters.adjustments.sunrise += user.sunrise
        parameters.adjustments.dhuhr += user.dhuhr
        parameters.adjustments.asr += user.asr
        parameters.adjustments.maghrib += user.maghrib
        parameters.adjustments.isha += user.isha
        return parameters
    }
}
