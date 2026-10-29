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
                Text("Allow Location for iMiqaat in System Settings › Privacy & Security, or choose a city in iMiqaat's Settings.")
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
            // Between an adhan and its iqamah, count down to the iqamah instead, and on Fridays
            // to the khutbah first.
            let pending = schedule.pendingIqamah(at: now)
            let khutbah = schedule.khutbah(on: now).flatMap { today.dhuhr <= now && now < $0 ? $0 : nil }
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        khutbah.map { "Khutbah in \(countdown(to: $0))" }
                            ?? pending.map { "\(schedule.name(of: $0.prayer, on: now)) iqamah in \(countdown(to: $0.time))" }
                            ?? "\(schedule.name(of: next.prayer, on: next.time)) in \(countdown(to: next.time))"
                    )
                    .font(.title2.bold())
                    Text(hijriDate)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    if !schedule.iqamahTimes.isEmpty {
                        HStack {
                            Spacer()
                            Text("Adhan")
                            Text("Iqamah").frame(width: 56, alignment: .trailing)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    ForEach(Prayer.allCases, id: \.self) { prayer in
                        // After Isha the next prayer is tomorrow's Fajr, so match on time, not name.
                        let isNext = khutbah != nil ? prayer == .dhuhr : pending.map { $0.prayer == prayer } ?? (today.time(for: prayer) == next.time)
                        HStack {
                            Text(schedule.name(of: prayer, on: now))
                            Spacer()
                            Text(schedule.clock(today.time(for: prayer)))
                            if !schedule.iqamahTimes.isEmpty {
                                // The iqamah column, blank for prayers without one.
                                Text(schedule.iqamah(for: prayer, on: now).map(schedule.clock) ?? "")
                                    .frame(width: 56, alignment: .trailing)
                            }
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

extension PrayerSchedule {
    /// The prayer's name on the day containing `date`: Dhuhr is Jumu'ah on Fridays.
    public func name(of prayer: Prayer, on date: Date) -> String {
        isJumuah(prayer, on: date) ? "Jumu'ah" : prayer.name
    }

    /// The menu-bar item's text: the next prayer and its time, for example "Asr 15:55".
    public func menuBarTitle(at date: Date) -> String? {
        next(after: date).map { "\(name(of: $0.prayer, on: $0.time)) \(clock($0.time))" }
    }
}
