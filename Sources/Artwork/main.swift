import Adhan
import Foundation
import ImageIO
import PrayerKit
import SwiftUI
import WidgetUI

// Renders the project's images from the real views, so they can be regenerated with one command.
let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 2, ["icon", "screenshots"].contains(arguments[0]) else {
    FileHandle.standardError.write(Data("usage: swift run Artwork <icon|screenshots> <output dir>\n".utf8))
    exit(64)
}
let output = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}

/// Writes `view` as a PNG, at `scale` pixels per point.
@MainActor
func render(_ view: some View, to url: URL, scale: CGFloat) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    guard
        let image = renderer.cgImage,
        let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fail("can't render \(url.lastPathComponent)") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fail("can't write \(url.path)") }
}

switch arguments[0] {
case "icon":
    // An .iconset holds each size at 1x and 2x; iconutil packs it into AppIcon.icns.
    let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
    try? FileManager.default.removeItem(at: iconset)
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let pixels = points * scale
            let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
            render(AppIcon(simplified: pixels <= 64).frame(width: CGFloat(pixels), height: CGFloat(pixels)), to: iconset.appendingPathComponent(name), scale: 1)
        }
    }
    let icns = output.appendingPathComponent("AppIcon.icns")
    let iconutil = try Process.run(URL(fileURLWithPath: "/usr/bin/iconutil"), arguments: ["-c", "icns", iconset.path, "-o", icns.path])
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else { fail("iconutil failed") }
    print(icns.path)

default:
    // Fixed sample data, never the developer's location: prayer times reveal roughly where someone lives.
    let makkah = PrayerSchedule(
        coordinates: Coordinates(latitude: 21.427009, longitude: 39.828685),
        parameters: CalculationMethod.ummAlQura.params,
        timeZone: TimeZone(identifier: "Asia/Riyadh")!
    )
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = makkah.timeZone
    let afternoon = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 14, minute: 20))!

    // shortcut: text follows the Mac's language and 12/24-hour setting; pin the locale when the card is localized (#49).
    for (name, card) in [
        ("card", CardView(.times(makkah, now: afternoon))),
        ("card-finding-location", CardView(.findingLocation)),
        ("card-location-denied", CardView(.denied)),
    ] {
        let url = output.appendingPathComponent("\(name)@2x.png")
        render(card, to: url, scale: 2)
        print(url.path)
    }
}
