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
        .frame(width: 460)
    }
}
