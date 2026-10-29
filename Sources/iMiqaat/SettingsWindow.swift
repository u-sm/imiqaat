import Adhan
import AppKit
import Combine
import PrayerKit
import SwiftUI

/// The Settings window, opened from the menu. Created on first use and kept, so it reopens
/// where the user left it.
@MainActor
final class SettingsWindow {
    private lazy var window: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(settings: Settings())))
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

/// The saved settings as bindings. Views redraw on any change, including ones made from the menu.
@MainActor
private final class Settings: ObservableObject {
    private let defaults = UserDefaults.standard
    private var changes: AnyCancellable?

    init() {
        changes = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.objectWillChange.send() } }
    }

    func binding<Value>(_ setting: ReferenceWritableKeyPath<UserDefaults, Value>) -> Binding<Value> {
        Binding(get: { self.defaults[keyPath: setting] }, set: { self.defaults[keyPath: setting] = $0 })
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: Settings

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
