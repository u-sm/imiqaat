import Adhan
import PrayerKit
import SwiftUI

struct CardView: View {
    @ObservedObject var location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("iMiqaat")
                .font(.title2.bold())
            Text(status)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // shortcut: worked out only when the view redraws, so it goes stale; v0.3 recomputes on day, clock and wake changes.
    private var status: String {
        // A cached fix may be out of date, so don't show it once access is revoked.
        if location.isDenied {
            return "Allow Location for iMiqaat in System Settings › Privacy & Security."
        }
        guard let coordinates = location.coordinates else { return "Finding your location…" }
        let schedule = PrayerSchedule(
            coordinates: coordinates,
            // shortcut: Muslim World League for everyone; the method picker comes in v0.4.
            parameters: CalculationMethod.muslimWorldLeague.params,
            timeZone: .current
        )
        guard let next = schedule.next(after: Date()) else { return "Prayer times can't be calculated here." }
        return "\("\(next.prayer)".capitalized) at \(next.time.formatted(date: .omitted, time: .shortened))"
    }
}
