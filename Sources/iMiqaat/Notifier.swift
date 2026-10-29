import Foundation
import PrayerKit
import UserNotifications
import WidgetUI

/// Sends the reminder notifications: keeps the next two days' scheduled with the system,
/// and sends them again only when they change.
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    // Nil outside an app bundle, as with `swift run`, where UserNotifications crashes.
    private let center = Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()
    private var scheduled: [String] = []
    private var sending: Task<Void, Never>?

    override init() {
        super.init()
        center?.delegate = self
    }

    /// Call whenever the schedule or settings may have changed; it's cheap when nothing has.
    func update(_ schedule: PrayerSchedule?, reminders: Reminders) {
        guard let center else { return }
        let requests = schedule.map { schedule in schedule.alerts(reminders, after: Date()).map { request(for: $0, in: schedule) } } ?? []
        // The text too, not only the IDs: an iqamah or clock-format change keeps the IDs.
        let sent = requests.map { "\($0.identifier) \($0.content.title) \($0.content.body)" }
        guard sent != scheduled else { return }
        scheduled = sent
        sending?.cancel()
        center.removeAllPendingNotificationRequests()
        guard !requests.isEmpty else { return }
        sending = Task {
            // Asks the first time; afterwards it returns the user's choice without asking.
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else {
                // Try again on the next update, in case the user allows it in System Settings.
                scheduled = []
                return
            }
            for request in requests where !Task.isCancelled {
                try? await center.add(request)
            }
        }
    }

    private func request(for alert: PrayerAlert, in schedule: PrayerSchedule) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        let name = schedule.name(of: alert.prayer, on: alert.time)
        content.title = "\(name)\(alert.isIqamah ? " iqamah" : "") — \(schedule.clock(alert.time))"
        if !alert.isIqamah, let iqamah = schedule.iqamah(for: alert.prayer, on: alert.time) {
            content.body = "Iqamah \(schedule.clock(iqamah))"
        }
        content.sound = .default
        // A fixed moment, so a change of the Mac's time zone doesn't move it.
        let moment = Calendar(identifier: .gregorian).dateComponents(in: .gmt, from: alert.date)
        return UNNotificationRequest(identifier: alert.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: moment, repeats: false))
    }

    // Show the banner even while the Settings window is in front.
    nonisolated func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
