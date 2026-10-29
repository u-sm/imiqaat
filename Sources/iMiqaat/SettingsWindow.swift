import Adhan
import AppKit
import MapKit
import PrayerKit
import SwiftUI

/// The Settings window, opened from the menu, with its tabs in the toolbar like macOS's own
/// Settings windows. Created on first use and kept, so it reopens where the user left it.
@MainActor
final class SettingsWindow {
    private lazy var window: NSWindow = {
        let settings = Settings(), search = CitySearch()
        let tabs = NSTabViewController()
        // Not SwiftUI's TabView: from the macOS 26 SDK its glass tab bar blurs the labels on 1x displays.
        tabs.tabStyle = .toolbar
        for page in SettingsPage.allCases {
            let controller = NSHostingController(rootView: SettingsView(page: page, settings: settings, search: search))
            // The window shows the selected tab's title, as macOS's own Settings windows do.
            controller.title = page.title
            // Report the form's size, so the window fits it rather than a 500-point default.
            controller.sizingOptions = .preferredContentSize
            let item = NSTabViewItem(viewController: controller)
            item.label = page.title
            item.image = NSImage(systemSymbolName: page.symbol, accessibilityDescription: nil)
            tabs.addTabViewItem(item)
        }
        let window = NSWindow(contentViewController: tabs)
        window.toolbarStyle = .preference
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }()

    func show() {
        // shortcut: activates without a Dock icon, so the window isn't in Command-Tab; switch to
        // the regular activation policy while it's open if users lose it behind other windows.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

/// City search with Apple Maps. It runs when the user presses Return, so Apple receives one
/// request per search rather than one per keystroke.
@MainActor
private final class CitySearch: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [City] = []
    /// Shown when a search finds nothing, which is also what an offline search returns.
    @Published private(set) var message: String?
    private var search: Task<Void, Never>?

    func run() {
        // A newer search replaces an older one, even if the older answer arrives last.
        search?.cancel()
        message = nil
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        search = Task {
            let items = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
            guard !Task.isCancelled else { return }
            // A city without a time zone can't be shown in its own time, so leave it out.
            results = items.compactMap { item in
                guard let timeZone = item.timeZone else { return nil }
                let place = item.placemark
                // Apple's short address names the region where places share a name:
                // "Portland, OR, United States" and "Portland, ME, United States".
                let name = place.title ?? item.name ?? ""
                return City(name: name, coordinates: Coordinates(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude), timeZone: timeZone)
            }
            message = results.isEmpty ? "No cities found. Check the spelling or your connection." : nil
        }
    }

    func clear() {
        search?.cancel()
        query = ""
        results = []
        message = nil
    }
}

private enum SettingsPage: CaseIterable {
    case general, card, adjustments, iqamah, reminders

    var title: String { "\(self)".capitalized }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .card: "lock.display"
        case .adjustments: "slider.horizontal.3"
        case .iqamah: "person.3"
        case .reminders: "bell"
        }
    }
}

private struct SettingsView: View {
    let page: SettingsPage
    @ObservedObject var settings: Settings
    @ObservedObject var search: CitySearch

    var body: some View {
        Group {
            switch page {
            case .general: general
            case .card: card
            case .adjustments: adjustments
            case .iqamah: iqamah
            case .reminders: reminders
            }
        }
        // Grouped forms scroll, so they ask for no height; without one the window shrinks to the toolbar.
        .frame(width: 460, height: 430)
    }

    private var general: some View {
        Form {
            Section {
                LabeledContent("Times for", value: settings.defaults.city?.name ?? "Current location")
                if settings.defaults.city != nil {
                    Button("Use Current Location") { settings.defaults.city = nil }
                }
                TextField("Choose a city", text: $search.query, prompt: Text("Search, then press Return"))
                    .onSubmit { search.run() }
                ForEach(search.results, id: \.name) { city in
                    Button(city.name) {
                        settings.defaults.city = city
                        search.clear()
                    }
                }
                if let message = search.message {
                    Text(message).foregroundColor(.secondary)
                }
            } header: {
                Text("Location")
            } footer: {
                Text("City search sends what you type to Apple Maps. Prayer times are still calculated on this Mac.")
                    .foregroundColor(.secondary)
            }
            Section("Calculation") {
                Picker("Calculation method", selection: settings.binding(\.calculationMethod)) {
                    ForEach(PrayerMethod.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Picker("Asr method", selection: settings.binding(\.madhab)) {
                    ForEach(Madhab.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Picker("High latitudes", selection: settings.binding(\.highLatitudeRule)) {
                    Text("Automatic").tag(HighLatitudeRule?.none)
                    ForEach(HighLatitudeRule.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var adjustments: some View {
        Form {
            Section {
                ForEach(Prayer.allCases, id: \.self) { prayer in
                    adjustment(for: prayer)
                }
            } footer: {
                Text("Move a time earlier or later to match your mosque's timetable.")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func adjustment(for prayer: Prayer) -> some View {
        let adjustments: ReferenceWritableKeyPath<UserDefaults, PrayerAdjustments> = \.prayerAdjustments
        let minutes = settings.binding(adjustments.appending(path: prayer.adjustment))
        return Stepper(value: minutes, in: -30...30) {
            HStack {
                Text(prayer.name)
                Spacer()
                Text(minutes.wrappedValue == 0 ? "None" : "\(minutes.wrappedValue > 0 ? "+" : "−")\(abs(minutes.wrappedValue)) min")
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum IqamahKind: Hashable {
    case off, afterAdhan, fixed
}

extension SettingsView {
    var iqamah: some View {
        Form {
            let times: ReferenceWritableKeyPath<UserDefaults, IqamahTimes> = \.iqamahTimes
            Section {
                ForEach([Prayer.fajr, .dhuhr, .asr, .maghrib, .isha], id: \.self) { prayer in
                    iqamahRows(prayer.name, times.appending(path: \IqamahTimes.[prayer]), after: prayer)
                }
            } footer: {
                Text("A fixed time is skipped on days when it comes before the adhan.")
                    .foregroundColor(.secondary)
            }
            Section {
                iqamahRows("Khutbah", times.appending(path: \.khutbah), after: .dhuhr)
                iqamahRows("Jumu'ah", times.appending(path: \.jumuah), after: .dhuhr)
            } header: {
                Text("Fridays")
            } footer: {
                Text("On Fridays, Dhuhr shows as Jumu'ah, using these times if they're set.")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// Off, minutes after `prayer`'s adhan, or a fixed time, for one iqamah setting.
    @ViewBuilder
    private func iqamahRows(_ title: String, _ path: ReferenceWritableKeyPath<UserDefaults, Iqamah?>, after prayer: Prayer) -> some View {
        let setting = settings.binding(path)
        // Today's schedule, from the chosen city or the last known location, to suggest and check times.
        let schedule = settings.defaults.prayerSchedule(deviceCoordinates: settings.defaults.cachedCoordinates)
        let adhan = schedule?.times(on: Date())?.time(for: prayer)
        let kind = Binding<IqamahKind>(
            get: {
                switch setting.wrappedValue {
                case nil: .off
                case .afterAdhan: .afterAdhan
                case .fixed: .fixed
                }
            },
            set: { kind in
                switch kind {
                case .off: setting.wrappedValue = nil
                case .afterAdhan: setting.wrappedValue = .afterAdhan(minutes: 15)
                case .fixed:
                    // Start from today's adhan rounded up to the quarter hour, so it's after the adhan.
                    let start = adhan.map { Date(timeIntervalSinceReferenceDate: ($0.timeIntervalSinceReferenceDate / 900).rounded(.up) * 900) } ?? Date()
                    var calendar = Calendar.current
                    calendar.timeZone = schedule?.timeZone ?? .current
                    let clock = calendar.dateComponents([.hour, .minute], from: start)
                    setting.wrappedValue = .fixed(hour: clock.hour ?? 12, minute: clock.minute ?? 0)
                }
            }
        )
        Picker(title, selection: kind) {
            Text("Off").tag(IqamahKind.off)
            Text("After the adhan").tag(IqamahKind.afterAdhan)
            Text("At a fixed time").tag(IqamahKind.fixed)
        }
        switch setting.wrappedValue {
        case let .afterAdhan(minutes):
            Stepper(value: Binding(get: { minutes }, set: { setting.wrappedValue = .afterAdhan(minutes: $0) }), in: 0...90, step: 5) {
                Text("\(minutes) min after the adhan").foregroundColor(.secondary)
            }
        case let .fixed(hour, minute):
            let time = Binding<Date>(
                get: { Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date() },
                set: {
                    let clock = Calendar.current.dateComponents([.hour, .minute], from: $0)
                    setting.wrappedValue = .fixed(hour: clock.hour ?? hour, minute: clock.minute ?? minute)
                }
            )
            DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
            if let adhan, let schedule, isBefore(hour: hour, minute: minute, adhan, in: schedule.timeZone) {
                Text("Today this is before the adhan, so it's skipped today.")
                    .foregroundColor(.orange)
            }
        case nil:
            EmptyView()
        }
    }
}

extension SettingsView {
    /// The Lock Screen card's look.
    var card: some View {
        Form {
            Section {
                Picker("Style", selection: settings.binding(\.cardStyle)) {
                    Text("Full: today's times").tag(CardStyle.full)
                    Text("Compact: only what's next").tag(CardStyle.compact)
                }
                .pickerStyle(.radioGroup)
                Picker("Position", selection: settings.binding(\.cardPosition)) {
                    ForEach(CardPosition.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Picker("Margin", selection: settings.binding(\.cardMargin)) {
                    ForEach(CardMargin.allCases, id: \.self) { Text("\($0)".capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
            } footer: {
                Text("Compact shows the next prayer's countdown and time, and the Hijri date.")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    var reminders: some View {
        Form {
            let path: ReferenceWritableKeyPath<UserDefaults, Reminders> = \.reminders
            Section {
                ForEach(Prayer.allCases, id: \.self) { prayer in
                    reminderPicker(prayer.name, path.appending(path: \Reminders.[prayer]), minutes: [0, 5, 10, 15, 30])
                }
                reminderPicker("Before the iqamah", path.appending(path: \.beforeIqamah), minutes: [5, 10, 15])
            } footer: {
                Text("The iqamah reminder is for prayers with an iqamah time. iMiqaat asks to send notifications the first time you turn one on; if you said no, allow them in System Settings › Notifications.")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    /// Off, or a number of minutes before; 0 reads "At the adhan".
    private func reminderPicker(_ title: String, _ path: ReferenceWritableKeyPath<UserDefaults, Int?>, minutes: [Int]) -> some View {
        Picker(title, selection: settings.binding(path)) {
            Text("Off").tag(Int?.none)
            ForEach(minutes, id: \.self) { Text($0 == 0 ? "At the adhan" : "\($0) min before").tag(Int?.some($0)) }
        }
    }
}

/// Whether `hour:minute` today, in `timeZone`, comes before `adhan`.
private func isBefore(hour: Int, minute: Int, _ adhan: Date, in timeZone: TimeZone) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: adhan).map { $0 < adhan } ?? false
}

extension Prayer {
    /// Where this prayer's offset lives in adhan-swift's adjustments.
    var adjustment: WritableKeyPath<PrayerAdjustments, Int> {
        switch self {
        case .fajr: \.fajr
        case .sunrise: \.sunrise
        case .dhuhr: \.dhuhr
        case .asr: \.asr
        case .maghrib: \.maghrib
        case .isha: \.isha
        }
    }
}
