import Adhan
import Foundation
import PrayerKit
import Testing

@Test func discouragedTimesAreOffUntilTurnedOn() {
    let defaults = emptyDefaults()
    #expect(defaults.discouragedTimes == nil)
    var lengths = DiscouragedTimes()
    lengths.beforeDhuhr = 5
    defaults.discouragedTimes = lengths
    #expect(defaults.discouragedTimes == lengths)
}

// Makkah on 4 February 2016, with the default lengths: 15, 10 and 15 minutes.
@Test func discouragedTimesStartAndEndOnTheMinute() throws {
    let today = try #require(makkah.times(on: makkahTime(2016, 2, 4, 12, 0)))
    let lengths = DiscouragedTimes()
    let minute: TimeInterval = 60
    let windows = [
        (today.sunrise, today.sunrise.addingTimeInterval(15 * minute)),
        (today.dhuhr.addingTimeInterval(-10 * minute), today.dhuhr),
        (today.maghrib.addingTimeInterval(-15 * minute), today.maghrib),
    ]
    for (start, end) in windows {
        #expect(makkah.discouragedTimeEnd(at: start.addingTimeInterval(-1), lengths) == nil)
        #expect(makkah.discouragedTimeEnd(at: start, lengths) == end)
        #expect(makkah.discouragedTimeEnd(at: end.addingTimeInterval(-1), lengths) == end)
        #expect(makkah.discouragedTimeEnd(at: end, lengths) == nil)
    }
}
