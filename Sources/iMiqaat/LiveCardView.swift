import Adhan
import PrayerKit
import SwiftUI
import WidgetUI

/// The card in the Lock Screen window, kept current with the location, the settings and the clock.
struct LiveCardView: View {
    @ObservedObject var location: Location
    @ObservedObject var settings: Settings

    var body: some View {
        // The window covers the screen, so its height places the centered positions.
        GeometryReader { screen in
            card
                .padding(settings.defaults.cardPosition.padding(settings.defaults.cardMargin, screenHeight: screen.size.height))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.defaults.cardPosition.alignment)
        }
    }

    private var card: some View {
        Group {
            // A cached fix may be out of date, so don't use it once access is revoked.
            if let schedule = settings.defaults.prayerSchedule(deviceCoordinates: location.isDenied ? nil : location.coordinates) {
                // Recalculating from the current time every minute also covers midnight,
                // sleep and wake, and time-zone changes.
                TimelineView(.everyMinute) { context in
                    CardView(.times(schedule, now: context.date), style: settings.defaults.cardStyle, textSize: settings.defaults.cardTextSize, showSunnahTimes: settings.defaults.showSunnahTimes)
                }
            } else if location.isDenied {
                CardView(.denied, textSize: settings.defaults.cardTextSize)
            } else {
                CardView(.findingLocation, textSize: settings.defaults.cardTextSize)
            }
        }
    }
}

extension CardPosition {
    var alignment: Alignment {
        switch self {
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topLeft: .topLeading
        case .topRight: .topTrailing
        case .centerHigh: .top
        case .center: .center
        case .centerLow: .bottom
        }
    }

    /// The space around the card: the margin in a corner. Centered high and low, a share of the screen's
    /// height that clears the Lock Screen's clock above or its login controls below.
    func padding(_ margin: CardMargin, screenHeight: CGFloat) -> EdgeInsets {
        switch self {
        case .centerHigh: EdgeInsets(top: screenHeight * 0.28, leading: 0, bottom: 0, trailing: 0)
        case .center: EdgeInsets()
        case .centerLow: EdgeInsets(top: 0, leading: 0, bottom: screenHeight * 0.26, trailing: 0)
        default: EdgeInsets(top: margin.points, leading: margin.points, bottom: margin.points, trailing: margin.points)
        }
    }

    var title: String {
        switch self {
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .centerHigh: "Center High"
        case .center: "Center"
        case .centerLow: "Center Low"
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
