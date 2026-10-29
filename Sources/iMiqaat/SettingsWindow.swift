import Adhan
import AppKit
import MapKit
import PrayerKit
import SwiftUI

/// The Settings window, opened from the menu. Created on first use and kept, so it reopens
/// where the user left it.
@MainActor
final class SettingsWindow {
    private lazy var window: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(settings: Settings(), search: CitySearch())))
        window.title = "iMiqaat Settings"
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

    func run() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        Task {
            let items = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []
            // A city without a time zone can't be shown in its own time, so leave it out.
            results = items.compactMap { item in
                guard let timeZone = item.timeZone else { return nil }
                let place = item.placemark
                let name = [place.locality ?? item.name, place.country].compactMap { $0 }.joined(separator: ", ")
                return City(name: name, coordinates: Coordinates(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude), timeZone: timeZone)
            }
        }
    }

    func clear() {
        query = ""
        results = []
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var search: CitySearch

    var body: some View {
        TabView {
            general.tabItem { Text("General") }
            adjustments.tabItem { Text("Adjustments") }
        }
        .frame(width: 460)
        .padding(.top, 8)
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
