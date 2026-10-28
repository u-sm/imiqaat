import Adhan
import PrayerKit
import SwiftUI

/// The Lock Screen card, drawn from plain values so the app and the Artwork tool share it.
public struct CardView: View {
    public enum Content {
        case denied
        case findingLocation
        case times(PrayerSchedule, now: Date)
    }

    let content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public var body: some View {
        Group {
            switch content {
            case .denied:
                Text("Allow Location for iMiqaat in System Settings › Privacy & Security.")
            case .findingLocation:
                Text("Finding your location…")
            case let .times(schedule, now):
                PrayerTimesView(schedule: schedule, now: now)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(width: 280, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PrayerTimesView: View {
    let schedule: PrayerSchedule
    let now: Date

    var body: some View {
        if let today = schedule.times(on: now), let next = schedule.next(after: now) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(next.prayer.name) in \(countdown(to: next.time))")
                        .font(.title2.bold())
                    Text(hijriDate)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    ForEach(Prayer.allCases, id: \.self) { prayer in
                        // After Isha the next prayer is tomorrow's Fajr, so match on time, not name.
                        let isNext = today.time(for: prayer) == next.time
                        HStack {
                            Text(prayer.name)
                            Spacer()
                            // In the schedule's time zone, which is the Mac's in the app.
                            Text(today.time(for: prayer).formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: schedule.timeZone)))
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

extension Prayer {
    public var name: String {
        "\(self)".capitalized
    }
}
