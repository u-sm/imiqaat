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
    contentRect: NSRect(x: 0, y: 0, width: 280, height: 320),
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

@MainActor
func card() -> CardView {
    CardView(location: location, parameters: UserDefaults.standard.calculationParameters)
}
let cardView = NSHostingView(rootView: card())
window.contentView = cardView

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

let statusMenu = StatusMenu(location: location) { cardView.rootView = card() }

app.run()
