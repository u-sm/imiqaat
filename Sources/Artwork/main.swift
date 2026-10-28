import Adhan
import Foundation
import ImageIO
import PrayerKit
import SwiftUI
import WidgetUI

// Renders the project's images from the real views, so they can be regenerated with one command.
let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 2, arguments[0] == "screenshots" else {
    FileHandle.standardError.write(Data("usage: swift run Artwork screenshots <output dir>\n".utf8))
    exit(64)
}
let output = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

// Fixed sample data, never the developer's location: prayer times reveal roughly where someone lives.
let makkah = PrayerSchedule(
    coordinates: Coordinates(latitude: 21.427009, longitude: 39.828685),
    parameters: CalculationMethod.ummAlQura.params,
    timeZone: TimeZone(identifier: "Asia/Riyadh")!
)
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = makkah.timeZone
let afternoon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 14, minute: 20))!

/// Writes `view` to `<output>/<name>@2x.png`.
// shortcut: text follows the Mac's language and 12/24-hour setting; pin the locale when the card is localized (#49).
@MainActor
func render(_ view: some View, as name: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    let url = output.appendingPathComponent("\(name)@2x.png")
    guard
        let image = renderer.cgImage,
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else {
        FileHandle.standardError.write(Data("can't render \(name)\n".utf8))
        exit(1)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        FileHandle.standardError.write(Data("can't write \(url.path)\n".utf8))
        exit(1)
    }
    print(url.path)
}

render(CardView(.times(makkah, now: afternoon)), as: "card")
render(CardView(.findingLocation), as: "card-finding-location")
render(CardView(.denied), as: "card-location-denied")
