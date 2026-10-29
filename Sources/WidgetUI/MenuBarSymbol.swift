import AppKit

/// The menu-bar symbol: the app icon's sun path, in one colour. A template image, so
/// macOS tints it for light and dark menu bars.
@MainActor
public let menuBarSymbol: NSImage = {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
        // The icon's arc and sun, scaled to an 18 pt square.
        let center = NSPoint(x: 9, y: 12.5), radius = 7.0
        func point(_ degrees: Double) -> NSPoint {
            let angle = degrees * .pi / 180
            return NSPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
        }
        let arc = NSBezierPath()
        arc.move(to: point(196))
        for degrees in stride(from: 196.0, through: -16, by: -4) { arc.line(to: point(degrees)) }
        arc.lineWidth = 1.5
        arc.lineCapStyle = .round
        NSColor.black.setStroke()
        arc.stroke()
        let sun = point(42)
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: sun.x - 2.75, y: sun.y - 2.75, width: 5.5, height: 5.5)).fill()
        return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "iMiqaat"
    return image
}()
