import AppKit
import PrayerKit
import SwiftUI
import WidgetUI

// Nil if a macOS update removed the private API; the app then runs from the menu bar only.
let moveToLockScreen = makeLockScreenSpace()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let location = Location()

let window = NSWindow(
    contentRect: .zero,
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

window.contentView = NSHostingView(rootView: LiveCardView(location: location, settings: Settings()))

// The window covers the screen, so the card can sit in any corner without resizing it, and
// lets clicks through. Fitted again when displays change.
// shortcut: main display only; follow the Lock Screen to other displays if users ask.
@MainActor func fitToScreen() {
    if let screen = NSScreen.main { window.setFrame(screen.frame, display: true) }
}
fitToScreen()
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
    MainActor.assumeIsolated { fitToScreen() }
}

if let moveToLockScreen {
    moveToLockScreen(window)
    window.orderFrontRegardless()
}

// Hide with alpha rather than orderOut, so the window never leaves the Lock Screen Space.
let session = CGSessionCopyCurrentDictionary() as? [String: Any]
window.alphaValue = session?["CGSSessionScreenIsLocked"] as? Bool == true && UserDefaults.standard.showOnLockScreen ? 1 : 0

for (name, alpha) in [("com.apple.screenIsLocked", 1.0), ("com.apple.screenIsUnlocked", 0.0)] {
    DistributedNotificationCenter.default().addObserver(
        forName: .init(name), object: nil, queue: .main
    ) { _ in
        // The setting is read at each lock, so turning it back on needs no restart.
        MainActor.assumeIsolated { window.alphaValue = UserDefaults.standard.showOnLockScreen ? alpha : 0 }
    }
}

let statusMenu = StatusMenu(location: location, lockScreenAvailable: moveToLockScreen != nil)

app.run()
