import Adhan
import PrayerKit
import SwiftUI
import WidgetUI

/// The card in the Lock Screen window, kept current with the location, the settings and the clock.
struct LiveCardView: View {
    @ObservedObject var location: Location
    @ObservedObject var settings: Settings

    var body: some View {
        Group {
            // A cached fix may be out of date, so don't use it once access is revoked.
            if let schedule = settings.defaults.prayerSchedule(deviceCoordinates: location.isDenied ? nil : location.coordinates) {
                // Recalculating from the current time every minute also covers midnight,
                // sleep and wake, and time-zone changes.
                TimelineView(.everyMinute) { context in
                    CardView(.times(schedule, now: context.date), style: settings.defaults.cardStyle, textSize: settings.defaults.cardTextSize)
                }
            } else if location.isDenied {
                CardView(.denied, textSize: settings.defaults.cardTextSize)
            } else {
                CardView(.findingLocation, textSize: settings.defaults.cardTextSize)
            }
        }
        // The window covers the screen; the card sits in the chosen corner.
        .padding(settings.defaults.cardMargin.points)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.defaults.cardPosition.alignment)
    }
}

extension CardPosition {
    var alignment: Alignment {
        switch self {
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topLeft: .topLeading
        case .topRight: .topTrailing
        }
    }

    var title: String {
        switch self {
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        }
    }
}

extension CardMargin {
    var points: CGFloat {
        switch self {
        case .small: 24
        case .medium: 48
        case .large: 96
        }
    }
}
