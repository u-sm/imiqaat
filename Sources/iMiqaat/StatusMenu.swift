import Adhan
import AppKit
import Combine
import PrayerKit
import ServiceManagement

/// The menu-bar item: the next prayer and its time, and a menu of calculation settings.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let location: Location
    private let settingsChanged: () -> Void
    private var timer: Timer?
    private var locationChanges: AnyCancellable?

    /// `settingsChanged` runs after the user picks a new setting.
    init(location: Location, settingsChanged: @escaping () -> Void) {
        self.location = location
        self.settingsChanged = settingsChanged
        super.init()
        item.menu = NSMenu()
        item.menu?.delegate = self
        updateTitle()

        // Prayer times fall on whole minutes, so check at the start of every minute.
        let nextMinute = Calendar.current.nextDate(after: Date(), matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date()
        let timer = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateTitle() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        locationChanges = location.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            MainActor.assumeIsolated { self?.updateTitle() }
        }
    }

    private func updateTitle() {
        guard
            !location.isDenied,
            let coordinates = location.coordinates,
            let next = PrayerSchedule(
                coordinates: coordinates,
                parameters: UserDefaults.standard.calculationParameters,
                timeZone: .autoupdatingCurrent
            ).next(after: Date())
        else {
            item.button?.title = "iMiqaat"
            return
        }
        item.button?.title = "\(next.prayer.name) \(next.time.formatted(date: .omitted, time: .shortened))"
    }

    // Rebuilt on every open, so the ticks always match the saved settings.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let defaults = UserDefaults.standard
        menu.removeAllItems()
        menu.addItem(submenu("Calculation Method", CalculationMethod.allCases.filter { $0 != .other }.map { method in
            choice(method.title, isOn: defaults.calculationMethod == method) { defaults.calculationMethod = method }
        }))
        menu.addItem(submenu("Asr Method", Madhab.allCases.map { madhab in
            choice(madhab.title, isOn: defaults.madhab == madhab) { defaults.madhab = madhab }
        }))
        menu.addItem(submenu("High Latitudes", ([nil] + HighLatitudeRule.allCases).map { rule in
            choice(rule?.title ?? "Automatic", isOn: defaults.highLatitudeRule == rule) { defaults.highLatitudeRule = rule }
        }))
        menu.addItem(.separator())
        menu.addItem(ActionItem("Launch at Login", isOn: SMAppService.mainApp.status == .enabled) {
            Self.toggleLaunchAtLogin()
        })
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit iMiqaat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private static func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            try service.status == .enabled ? service.unregister() : service.register()
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
        // macOS can hold a new login item until the user approves it in System Settings.
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = NSMenu()
        items.forEach(item.submenu!.addItem)
        return item
    }

    private func choice(_ title: String, isOn: Bool, save: @escaping () -> Void) -> NSMenuItem {
        ActionItem(title, isOn: isOn) { [weak self] in
            save()
            self?.updateTitle()
            self?.settingsChanged()
        }
    }
}

/// A menu item that runs a closure, so each choice doesn't need its own @objc method.
private final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, isOn: Bool, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        state = isOn ? .on : .off
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }

    @objc private func run() { handler() }
}

extension CalculationMethod {
    var title: String {
        switch self {
        case .muslimWorldLeague: "Muslim World League"
        case .egyptian: "Egyptian General Authority of Survey"
        case .karachi: "University of Islamic Sciences, Karachi"
        case .ummAlQura: "Umm al-Qura, Makkah"
        case .dubai: "Dubai"
        case .moonsightingCommittee: "Moonsighting Committee"
        case .northAmerica: "ISNA (North America)"
        case .kuwait: "Kuwait"
        case .qatar: "Qatar"
        case .singapore: "Singapore"
        case .tehran: "Institute of Geophysics, Tehran"
        case .turkey: "Diyanet, Turkey"
        case .other: "Custom"
        }
    }
}

extension Madhab {
    var title: String {
        switch self {
        case .shafi: "Standard (Shafi'i, Maliki, Hanbali)"
        case .hanafi: "Hanafi"
        }
    }
}

extension HighLatitudeRule {
    var title: String {
        switch self {
        case .middleOfTheNight: "Middle of the Night"
        case .seventhOfTheNight: "Seventh of the Night"
        case .twilightAngle: "Twilight Angle"
        }
    }
}
