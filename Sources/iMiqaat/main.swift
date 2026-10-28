import AppKit
import SwiftUI

guard let moveToLockScreen = makeLockScreenSpace() else {
    print("SkyLight's private API is unavailable on this version of macOS.")
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 280, height: 96),
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
window.contentView = NSHostingView(rootView: SpikeView())

// shortcut: main display only, bottom-left corner; add placement settings when users ask.
if let screen = NSScreen.main {
    window.setFrameOrigin(NSPoint(x: screen.frame.minX + 48, y: screen.frame.minY + 48))
}

moveToLockScreen(window)
window.orderFrontRegardless()

app.run()

struct SpikeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("iMiqaat")
                .font(.title2.bold())
            Text("Lock Screen spike")
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
