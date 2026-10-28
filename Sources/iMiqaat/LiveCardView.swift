import Adhan
import PrayerKit
import SwiftUI
import WidgetUI

/// The card in the Lock Screen window, kept current with the location and the clock.
struct LiveCardView: View {
    @ObservedObject var location: Location
    let parameters: CalculationParameters

    var body: some View {
        Group {
            // A cached fix may be out of date, so don't show it once access is revoked.
            if location.isDenied {
                CardView(.denied)
            } else if let coordinates = location.coordinates {
                // Recalculating from the current time every minute also covers midnight,
                // sleep and wake, and time-zone changes.
                TimelineView(.everyMinute) { context in
                    CardView(.times(
                        PrayerSchedule(coordinates: coordinates, parameters: parameters, timeZone: .autoupdatingCurrent),
                        now: context.date
                    ))
                }
            } else {
                CardView(.findingLocation)
            }
        }
        // The window is taller than the card; keep the card in its bottom-left corner.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
}
