import Adhan
import AppKit
import Combine
import PrayerKit
import ServiceManagement
import WidgetUI

/// The menu-bar item: the app's symbol with the next prayer and its time, and a menu with the
/// calculation method and the Settings window. It also keeps the reminders scheduled.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let location: Location
    private let lockScreenAvailable: Bool
    private let settingsWindow = SettingsWindow()
    private let notifier = Notifier()
    private var timer: Timer?
    private var locationChanges: AnyCancellable?
    private var settingChanges: AnyCancellable?

    init(location: Location, lockScreenAvailable: Bool) {
        self.location = location
        self.lockScreenAvailable = lockScreenAvailable
        super.init()
        item.button?.image = menuBarSymbol
        item.button?.imagePosition = .imageLeading
        item.menu = NSMenu()
        item.menu?.delegate = self
        update()

        // Prayer times fall on whole minutes, so check at the start of every minute.
        let nextMinute = Calendar.current.nextDate(after: Date(), matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? Date()
        let timer = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        locationChanges = location.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        // Any settings change, from the menu or the Settings window.
        settingChanges = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: UserDefaults.standard)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.update() } }
    }

    private func update() {
        let defaults = UserDefaults.standard
        let schedule = defaults.prayerSchedule(deviceCoordinates: location.isDenied ? nil : location.coordinates)
        // Without times, the symbol alone; its accessibility description names the app.
        item.button?.title = schedule?.menuBarTitle(at: Date(), style: defaults.menuBarStyle) ?? ""
        notifier.update(schedule, reminders: defaults.reminders)
    }

    // Rebuilt on every open, so the ticks always match the saved settings.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let defaults = UserDefaults.standard
        menu.removeAllItems()
        if !lockScreenAvailable {
            // No action, so the item shows greyed out as a notice.
            menu.addItem(withTitle: "Lock Screen widget unavailable on this macOS version", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
        }
        // Quick access to the method; the other settings are in the Settings window.
        menu.addItem(submenu("Calculation Method", PrayerMethod.allCases.map { method in
            ActionItem(method.title, isOn: defaults.calculationMethod == method) { defaults.calculationMethod = method }
        }))
        menu.addItem(submenu("Menu Bar Shows", MenuBarStyle.allCases.map { style in
            ActionItem(style.title, isOn: defaults.menuBarStyle == style) { defaults.menuBarStyle = style }
        }))
        let settings = ActionItem("Settings…", isOn: false) { [weak self] in self?.settingsWindow.show() }
        settings.keyEquivalent = ","
        menu.addItem(settings)
        menu.addItem(.separator())
        if lockScreenAvailable {
            menu.addItem(ActionItem("Show on Lock Screen", isOn: defaults.showOnLockScreen) { defaults.showOnLockScreen.toggle() })
        }
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

extension PrayerMethod {
    var title: String {
        switch self {
        case let .adhan(method): method.title
        case .jakim: "JAKIM, Malaysia"
        }
    }
}

extension MenuBarStyle {
    var title: String {
        switch self {
        case .time: "Next Prayer Time"
        case .countdown: "Countdown"
        case .iconOnly: "Icon Only"
        }
    }
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
