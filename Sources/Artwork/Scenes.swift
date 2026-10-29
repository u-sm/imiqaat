import Adhan
import PrayerKit
import SwiftUI
import WidgetUI

/// The card where the app puts it: bottom-left, 48 pt from the edges, under the Lock Screen's
/// clock. The wallpaper is a stand-in in the icon's palette, not a macOS wallpaper.
struct LockScreenScene: View {
    let schedule: PrayerSchedule
    let now: Date

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(gradient: sky, startPoint: .top, endPoint: .bottom)
            VStack(spacing: 0) {
                Text(now.formatted(Date.FormatStyle(timeZone: schedule.timeZone).weekday(.wide).day().month(.wide)))
                    .font(.system(size: 18, weight: .semibold))
                Text(schedule.clock(now))
                    .font(.system(size: 96, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.9))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 40)
            CardView(.times(schedule, now: now))
                .padding(48)
        }
        .frame(width: 800, height: 500)
    }
}

/// The menu-bar item as the app shows it: the symbol and the next prayer.
struct MenuBarScene: View {
    let schedule: PrayerSchedule
    let now: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: menuBarSymbol)
            if let title = schedule.menuBarTitle(at: now) {
                Text(title)
            }
        }
        .font(.system(size: 13))
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Color(white: 0.92), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(8)
    }
}
