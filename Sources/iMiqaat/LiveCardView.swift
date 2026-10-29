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
                    CardView(.times(schedule, now: context.date))
                }
            } else if location.isDenied {
                CardView(.denied)
            } else {
                CardView(.findingLocation)
            }
        }
        // The window is taller than the card; keep the card in its bottom-left corner.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
