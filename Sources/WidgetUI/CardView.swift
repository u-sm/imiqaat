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
    let scale: CGFloat
    let showSunnahTimes: Bool
    let discouragedTimes: DiscouragedTimes?
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    public init(_ content: Content, style: CardStyle = .full, textSize: CardTextSize = .standard, showSunnahTimes: Bool = false, discouragedTimes: DiscouragedTimes? = nil) {
        self.content = content
        self.style = style
        self.showSunnahTimes = showSunnahTimes
        self.discouragedTimes = discouragedTimes
        scale = switch textSize {
        case .standard: 1
        case .large: 1.25
        case .extraLarge: 1.5
        }
    }

    public var body: some View {
        Group {
            switch content {
            case .denied:
                Text("Allow Location for iMiqaat in System Settings › Privacy & Security, or choose a city in iMiqaat's Settings.")
            case .findingLocation:
                Text("Finding your location…")
            case let .times(schedule, now):
                PrayerTimesView(schedule: schedule, now: now, style: style, scale: scale, showSunnahTimes: showSunnahTimes, discouragedTimes: discouragedTimes)
            }
        }
        .font(scaled(.body, 13, by: scale))
        .foregroundStyle(.white)
        .padding(20 * scale)
        .frame(width: 280 * scale, alignment: .leading)
        .background { background }
    }

    /// Frosted glass over the wallpaper, like system widgets, or a solid dark card when the user
    /// asks for less transparency or more contrast.
    @ViewBuilder private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let solid = reduceTransparency || contrast == .increased
        if #available(macOS 26, *), !solid {
            // The faint fill keeps white text readable over bright wallpapers, and is what the
            // Artwork tool's images show, since glass needs a real window behind it.
            ZStack {
                shape.fill(.black.opacity(0.2))
                Color.clear.glassEffect(.regular, in: shape)
            }
        } else {
            // shortcut: no blur before macOS 26; add an NSVisualEffectView if users there ask.
            shape.fill(.black.opacity(solid ? 0.85 : 0.45))
        }
    }
}

private struct PrayerTimesView: View {
    let schedule: PrayerSchedule
    let now: Date
    let style: CardStyle
    let scale: CGFloat
    let showSunnahTimes: Bool
    let discouragedTimes: DiscouragedTimes?

    var body: some View {
        if let today = schedule.times(on: now), let countdown = schedule.countdown(at: now) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.headline(at: now) ?? "")
                        .font(scaled(.title2, 17, by: scale).bold())
                        .accessibilityLabel(schedule.headline(at: now, width: .wide) ?? "")
                    // Compact keeps only this: the time it counts down to, and the Hijri date.
                    Text(style == .compact ? "\(schedule.clock(countdown.time)) · \(hijriDate)" : hijriDate)
                        .foregroundStyle(.secondary)
                    if let greeting {
                        Text(greeting).foregroundStyle(.secondary)
                    }
                    if let discouragedTimes, let end = schedule.discouragedTimeEnd(at: now, discouragedTimes) {
                        Text("Avoid voluntary prayer until \(schedule.clock(end))").foregroundStyle(.secondary)
                    }
                }
                if style == .full {
                    VStack(spacing: 4) {
                        if !schedule.iqamahTimes.isEmpty {
                            HStack {
                                Spacer()
                                Text("Adhan")
                                Text("Iqamah").frame(width: 56 * scale, alignment: .trailing)
                            }
                            .font(scaled(.caption, 10, by: scale))
                            .foregroundStyle(.secondary)
                            // Each row names its iqamah for VoiceOver.
                            .accessibilityHidden(true)
                        }
                        ForEach(Prayer.allCases, id: \.self) { prayer in
                            let isNext = prayer == countdown.row
                            let iqamah = schedule.iqamah(for: prayer, on: now).map(schedule.clock)
                            HStack {
                                Text(schedule.name(of: prayer, on: now))
                                Spacer()
                                Text(schedule.clock(today.time(for: prayer)))
                                if !schedule.iqamahTimes.isEmpty {
                                    // The iqamah column, blank for prayers without one.
                                    Text(iqamah ?? "")
                                        .frame(width: 56 * scale, alignment: .trailing)
                                }
                            }
                            .fontWeight(isNext ? .bold : .regular)
                            .foregroundStyle(isNext ? .primary : .secondary)
                            // One element per row for VoiceOver: "Asr, 15:55, iqamah 16:15, next prayer".
                            .accessibilityElement(children: .ignore)
                            .accessibilityAddTraits(.isStaticText)
                            .accessibilityLabel(
                                [schedule.name(of: prayer, on: now), schedule.clock(today.time(for: prayer)), iqamah.map { "iqamah \($0)" }, isNext ? "next prayer" : nil]
                                    .compactMap { $0 }.joined(separator: ", ")
                            )
                        }
                        if showSunnahTimes, let sunnah = schedule.sunnahTimes(at: now) {
                            ForEach([("Middle of the Night", sunnah.middleOfTheNight), ("Last Third of the Night", sunnah.lastThirdOfTheNight)], id: \.0) { name, time in
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Text(schedule.clock(time))
                                    if !schedule.iqamahTimes.isEmpty {
                                        // Keeps the time in the adhan column.
                                        Text("").frame(width: 56 * scale)
                                    }
                                }
                                .foregroundStyle(.secondary)
                                .accessibilityElement(children: .ignore)
                                .accessibilityAddTraits(.isStaticText)
                                .accessibilityLabel("\(name), \(schedule.clock(time))")
                            }
                        }
                    }
                }
            }
        } else {
            Text("Prayer times can't be calculated here.")
        }
    }

    /// The line under the Hijri date on an Islamic date: "Eid Mubarak", or the day's name. It
    /// follows the Hijri date shown, so it begins at Maghrib the evening before. Not for Ramadan.
    private var greeting: String? {
        switch IslamicDate(schedule.hijriDate(at: now)) {
        case .eidAlFitr, .eidAlAdha: "Eid Mubarak"
        case .ramadan, nil: nil
        case let date?: date.name
        }
    }

    private var hijriDate: String {
        let date = schedule.hijriDate(at: now)
        guard let day = date.day, let month = date.month, let year = date.year else { return "" }
        return "\(day) \(Calendar(identifier: .islamicUmmAlQura).monthSymbols[month - 1]) \(year) AH"
    }
}

/// A text style at the standard size, so the card lays out exactly as macOS's styles do, or the
/// style's macOS point size scaled up. macOS has no Dynamic Type to do this.
private func scaled(_ style: Font.TextStyle, _ points: CGFloat, by scale: CGFloat) -> Font {
    scale == 1 ? .system(style) : .system(size: points * scale)
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
    /// `.wide` gives VoiceOver's form, "Asr in 1 hour, 12 minutes".
    public func headline(at date: Date, width: Duration.UnitsFormatStyle.UnitWidth = .narrow) -> String? {
        countdown(at: date).map { countdown in
            let minutes = (countdown.time.timeIntervalSince(date) / 60).rounded(.up)
            return "\(countdown.label) in \(Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: width)))"
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
