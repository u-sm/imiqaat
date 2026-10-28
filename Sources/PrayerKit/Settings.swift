import Adhan
import Foundation

extension UserDefaults {
    /// Defaults to Muslim World League.
    public var calculationMethod: CalculationMethod {
        get { string(forKey: "calculationMethod").flatMap(CalculationMethod.init) ?? .muslimWorldLeague }
        set { set(newValue.rawValue, forKey: "calculationMethod") }
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

    /// The saved choices, combined into the parameters adhan-swift calculates with.
    public var calculationParameters: CalculationParameters {
        var parameters = calculationMethod.params
        parameters.madhab = madhab
        parameters.highLatitudeRule = highLatitudeRule
        return parameters
    }
}
