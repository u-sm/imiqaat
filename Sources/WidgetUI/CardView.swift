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
    let style: CardStyle

    public init(_ content: Content, style: CardStyle = .full) {
        self.content = content
        self.style = style
    }

    public var body: some View {
        Group {
            switch content {
            case .denied:
                Text("Allow Location for iMiqaat in System Settings › Privacy & Security, or choose a city in iMiqaat's Settings.")
            case .findingLocation:
                Text("Finding your location…")
            case let .times(schedule, now):
                PrayerTimesView(schedule: schedule, now: now, style: style)
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
    let style: CardStyle

    var body: some View {
        if let today = schedule.times(on: now), let countdown = schedule.countdown(at: now) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.headline(at: now) ?? "")
                        .font(.title2.bold())
                    // Compact keeps only this: the time it counts down to, and the Hijri date.
                    Text(style == .compact ? "\(schedule.clock(countdown.time)) · \(hijriDate)" : hijriDate)
                        .foregroundStyle(.secondary)
                }
                if style == .full {
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
                            let isNext = prayer == countdown.row
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
            }
        } else {
            Text("Prayer times can't be calculated here.")
        }
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

    /// What the card counts down to at `date`. On Fridays between the adhan and the khutbah,
    /// the khutbah; between an adhan and its iqamah, the iqamah; otherwise the next adhan.
    /// `row` is today's prayer to highlight: nil after Isha, when the next is tomorrow's Fajr.
    public func countdown(at date: Date) -> (label: String, time: Date, row: Prayer?)? {
        guard let today = times(on: date), let next = next(after: date) else { return nil }
        if let khutbah = khutbah(on: date), today.dhuhr <= date, date < khutbah {
            return ("Khutbah", khutbah, .dhuhr)
        }
        if let pending = pendingIqamah(at: date) {
            return ("\(name(of: pending.prayer, on: date)) iqamah", pending.time, pending.prayer)
        }
        return (name(of: next.prayer, on: next.time), next.time, today.time(for: next.prayer) == next.time ? next.prayer : nil)
    }

    /// The card's headline, for example "Asr in 1h 12m": what `countdown(at:)` picks, with the
    /// time left rounded up to the minute so it never reads 0m before the prayer.
    public func headline(at date: Date) -> String? {
        countdown(at: date).map { countdown in
            let minutes = (countdown.time.timeIntervalSince(date) / 60).rounded(.up)
            return "\(countdown.label) in \(Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow)))"
        }
    }

    /// The menu-bar item's text: the next prayer and its time ("Asr 15:55"), the card's
    /// headline ("Asr in 1h 12m"), or nil for the icon only.
    public func menuBarTitle(at date: Date, style: MenuBarStyle = .time) -> String? {
        switch style {
        case .time: next(after: date).map { "\(name(of: $0.prayer, on: $0.time)) \(clock($0.time))" }
        case .countdown: headline(at: date)
        case .iconOnly: nil
        }
    }
}
