import Adhan
import PrayerKit
import SwiftUI

struct CardView: View {
    @ObservedObject var location: Location

    var body: some View {
        Group {
            // A cached fix may be out of date, so don't show it once access is revoked.
            if location.isDenied {
                Text("Allow Location for iMiqaat in System Settings › Privacy & Security.")
            } else if let coordinates = location.coordinates {
                // Recalculating from the current time every minute also covers midnight,
                // sleep and wake, and time-zone changes.
                TimelineView(.everyMinute) { context in
                    PrayerTimesView(
                        schedule: PrayerSchedule(
                            coordinates: coordinates,
                            // shortcut: Muslim World League for everyone; the method picker comes in v0.4.
                            parameters: CalculationMethod.muslimWorldLeague.params,
                            timeZone: .autoupdatingCurrent
                        ),
                        now: context.date
                    )
                }
            } else {
                Text("Finding your location…")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(width: 280, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        // The window is taller than the card; keep the card in its bottom-left corner.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}

private struct PrayerTimesView: View {
    let schedule: PrayerSchedule
    let now: Date

    var body: some View {
        if let today = schedule.times(on: now), let next = schedule.next(after: now) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(name(next.prayer)) in \(countdown(to: next.time))")
                        .font(.title2.bold())
                    Text(hijriDate)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    ForEach(Prayer.allCases, id: \.self) { prayer in
                        // After Isha the next prayer is tomorrow's Fajr, so match on time, not name.
                        let isNext = today.time(for: prayer) == next.time
                        HStack {
                            Text(name(prayer))
                            Spacer()
                            Text(today.time(for: prayer).formatted(date: .omitted, time: .shortened))
                        }
                        .fontWeight(isNext ? .bold : .regular)
                        .foregroundStyle(isNext ? .primary : .secondary)
                    }
                }
            }
        } else {
            Text("Prayer times can't be calculated here.")
        }
    }

    private func name(_ prayer: Prayer) -> String {
        "\(prayer)".capitalized
    }

    /// "1h 12m", rounded up to the minute so it never reads 0m before the prayer.
    private func countdown(to time: Date) -> String {
        let minutes = (time.timeIntervalSince(now) / 60).rounded(.up)
        return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private var hijriDate: String {
        let date = schedule.hijriDate(at: now)
        guard let day = date.day, let month = date.month, let year = date.year else { return "" }
        return "\(day) \(Calendar(identifier: .islamicUmmAlQura).monthSymbols[month - 1]) \(year) AH"
    }
}
