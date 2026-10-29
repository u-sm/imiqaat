import SwiftUI

/// The app icon: the sun's path from dawn to night, with the five prayers on it and the
/// next one glowing. Drawn on Apple's 1024 px macOS grid: an 824 px rounded square with
/// 100 px margins, so macOS doesn't put it on a grey tile.
struct AppIcon: View {
    /// A bolder drawing with only the arc and the sun, for 64 px and below.
    let simplified: Bool

    private static let tile = Path(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerRadius: 185.4, style: .continuous)

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 1024, y: size.height / 1024)
            context.drawLayer { shadow in
                shadow.addFilter(.shadow(color: .black.opacity(0.3), radius: 14, y: 10))
                shadow.fill(Self.tile, with: .color(.black))
            }
            context.clip(to: Self.tile)
            context.fill(Self.tile, with: .linearGradient(sky, startPoint: CGPoint(x: 512, y: 100), endPoint: CGPoint(x: 512, y: 924)))

            // The arc is a circle around a point on the horizon; angles are in degrees above it.
            let center = CGPoint(x: 512, y: 640), radius = 320.0
            func point(_ degrees: Double) -> CGPoint {
                let angle = degrees * .pi / 180
                return CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
            }
            let arc = Path { path in
                path.move(to: point(196))
                for degrees in stride(from: 196.0, through: -16, by: -2) { path.addLine(to: point(degrees)) }
            }
            if !simplified {
                context.stroke(Path { $0.move(to: CGPoint(x: 100, y: center.y)); $0.addLine(to: CGPoint(x: 924, y: center.y)) }, with: .color(.white.opacity(0.18)), lineWidth: 6)
            }
            context.stroke(arc, with: .color(.white.opacity(simplified ? 0.75 : 0.55)), style: StrokeStyle(lineWidth: simplified ? 44 : 14, lineCap: .round))
            if !simplified {
                // Fajr, Dhuhr, Maghrib and Isha; Asr is the sun.
                for degrees in [192.0, 90, 4, -12] {
                    context.fill(circle(point(degrees), 22), with: .color(.white.opacity(0.9)))
                }
            }
            let asr = point(42), sunRadius = simplified ? 84.0 : 40
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: sunRadius * 1.2))
                glow.fill(circle(asr, sunRadius * 2.2), with: .color(sun.opacity(0.7)))
            }
            context.fill(circle(asr, sunRadius), with: .color(sun))
        }
    }

    private func circle(_ center: CGPoint, _ radius: Double) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

/// The icon's palette, shared with the DMG background.
let sky = Gradient(colors: [color(0x101538), color(0x332C6E), color(0x9A4F7A), color(0xF0965A)])
let sun = color(0xFFD36E)

func color(_ hex: UInt32) -> Color {
    Color(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
}
