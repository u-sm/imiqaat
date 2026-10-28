import Adhan
import AppKit
import PrayerKit
import SwiftUI

guard let moveToLockScreen = makeLockScreenSpace() else {
    print("SkyLight's private API is unavailable on this version of macOS.")
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let location = Location()

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 280, height: 112),
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = false
// Never take clicks or focus from the Lock Screen's password field.
window.ignoresMouseEvents = true
window.canBecomeVisibleWithoutLogin = true
window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
window.contentView = NSHostingView(rootView: CardView(location: location))

// shortcut: main display only, bottom-left corner; add placement settings when users ask.
if let screen = NSScreen.main {
    window.setFrameOrigin(NSPoint(x: screen.frame.minX + 48, y: screen.frame.minY + 48))
}

moveToLockScreen(window)
window.orderFrontRegardless()

// Hide with alpha rather than orderOut, so the window never leaves the Lock Screen Space.
let session = CGSessionCopyCurrentDictionary() as? [String: Any]
window.alphaValue = session?["CGSSessionScreenIsLocked"] as? Bool == true ? 1 : 0

for (name, alpha) in [("com.apple.screenIsLocked", 1.0), ("com.apple.screenIsUnlocked", 0.0)] {
    DistributedNotificationCenter.default().addObserver(
        forName: .init(name), object: nil, queue: .main
    ) { _ in
        MainActor.assumeIsolated { window.alphaValue = alpha }
    }
}

app.run()

struct CardView: View {
    @ObservedObject var location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("iMiqaat")
                .font(.title2.bold())
            Text(status)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // shortcut: worked out only when the view redraws, so it goes stale; v0.3 recomputes on day, clock and wake changes.
    private var status: String {
        // A cached fix may be out of date, so don't show it once access is revoked.
        if location.isDenied {
            return "Allow Location for iMiqaat in System Settings › Privacy & Security."
        }
        guard let coordinates = location.coordinates else { return "Finding your location…" }
        let schedule = PrayerSchedule(
            coordinates: coordinates,
            // shortcut: Muslim World League for everyone; the method picker comes in v0.4.
            parameters: CalculationMethod.muslimWorldLeague.params,
            timeZone: .current
        )
        guard let next = schedule.next(after: Date()) else { return "Prayer times can't be calculated here." }
        return "\("\(next.prayer)".capitalized) at \(next.time.formatted(date: .omitted, time: .shortened))"
    }
}
