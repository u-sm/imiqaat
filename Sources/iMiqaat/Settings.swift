import Combine
import Foundation
import SwiftUI

/// The saved settings, observed: views that use it redraw on any change, whether made from
/// the menu or the Settings window.
@MainActor
final class Settings: ObservableObject {
    let defaults = UserDefaults.standard
    private var changes: AnyCancellable?

    init() {
        changes = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.objectWillChange.send() } }
    }

    func binding<Value>(_ setting: ReferenceWritableKeyPath<UserDefaults, Value>) -> Binding<Value> {
        Binding(get: { self.defaults[keyPath: setting] }, set: { self.defaults[keyPath: setting] = $0 })
    }
}
