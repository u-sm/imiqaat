import SwiftUI

/// The DMG window's background, 660 × 400 pt. The icons sit on it at the positions set in
/// `scripts/dmg/settings.py`: the app at (165, 190) and Applications at (495, 190).
struct DMGBackground: View {
    /// Finder draws icon labels black in light mode and white in dark mode. This mauve has
    /// about 4.3:1 contrast with black and 5.7:1 with white, so the band under the labels
    /// keeps both readable.
    private static let labelBand = color(0xA35A82)

    var body: some View {
        Canvas { context, _ in
            let window = Path(CGRect(x: 0, y: 0, width: 660, height: 400))
            context.fill(window, with: .linearGradient(
                Gradient(stops: [
                    .init(color: color(0x101538), location: 0),
                    .init(color: color(0x332C6E), location: 0.3),
                    .init(color: Self.labelBand, location: 0.58),
                    .init(color: Self.labelBand, location: 0.76),
                    .init(color: color(0xF0965A), location: 1),
                ]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: 400)
            ))

            // The icon's sun path, as an arrow from the app to Applications.
            let center = CGPoint(x: 330, y: 230), radius = 100.0
            func point(_ degrees: Double) -> CGPoint {
                let angle = degrees * .pi / 180
                return CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
            }
            let arc = Path { path in
                path.move(to: point(160))
                for degrees in stride(from: 160.0, through: 24, by: -2) { path.addLine(to: point(degrees)) }
            }
            let white = Color.white.opacity(0.8)
            context.stroke(arc, with: .color(white), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // The head points along the arc's direction at its end, which is down and to the right.
            let tip = point(20), angle = 20 * Double.pi / 180
            let along = CGVector(dx: sin(angle), dy: cos(angle)), across = CGVector(dx: cos(angle), dy: -sin(angle))
            context.fill(Path { path in
                path.move(to: CGPoint(x: tip.x + along.dx * 6, y: tip.y + along.dy * 6))
                path.addLine(to: CGPoint(x: tip.x - along.dx * 10 + across.dx * 9, y: tip.y - along.dy * 10 + across.dy * 9))
                path.addLine(to: CGPoint(x: tip.x - along.dx * 10 - across.dx * 9, y: tip.y - along.dy * 10 - across.dy * 9))
                path.closeSubpath()
            }, with: .color(white))
            context.fill(Path(ellipseIn: CGRect(x: point(90).x - 9, y: point(90).y - 9, width: 18, height: 18)), with: .color(sun))

            context.draw(
                Text("Drag iMiqaat to Applications").font(.system(size: 20, weight: .semibold)).foregroundColor(.white),
                at: CGPoint(x: 330, y: 56)
            )
            // shortcut: needed while releases aren't notarized; remove with notarization (v1.0).
            context.draw(
                Text("First open: System Settings › Privacy & Security › Open Anyway").font(.system(size: 12, weight: .medium)).foregroundColor(color(0x101538)),
                at: CGPoint(x: 330, y: 362)
            )
        }
        .frame(width: 660, height: 400)
    }
}
