// Adapted from SkyLightWindow by Lakr Aream, MIT License:
// https://github.com/Lakr233/SkyLightWindow

import AppKit

private typealias MainConnectionID = @convention(c) () -> Int32
private typealias SpaceCreate = @convention(c) (Int32, Int32, Int32) -> Int32
private typealias SpaceSetAbsoluteLevel = @convention(c) (Int32, Int32, Int32) -> Int32
private typealias ShowSpaces = @convention(c) (Int32, CFArray) -> Int32
private typealias SpaceAddWindowsAndRemoveFromSpaces = @convention(c) (Int32, Int32, CFArray, Int32) -> Int32

// kSLSSpaceAbsoluteLevelNotificationCenterAtScreenLock, one step above the Lock Screen (300).
private let lockScreenSpaceLevel: Int32 = 400

/// Creates a private WindowServer Space above the Lock Screen and returns a function
/// that moves a window into it. Returns nil if SkyLight's private API is missing,
/// which can happen after a macOS update.
@MainActor
func makeLockScreenSpace() -> (@MainActor (NSWindow) -> Void)? {
    guard
        let skyLight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_NOW),
        let mainConnectionID = dlsym(skyLight, "SLSMainConnectionID"),
        let spaceCreate = dlsym(skyLight, "SLSSpaceCreate"),
        let spaceSetAbsoluteLevel = dlsym(skyLight, "SLSSpaceSetAbsoluteLevel"),
        let showSpaces = dlsym(skyLight, "SLSShowSpaces"),
        let addWindows = dlsym(skyLight, "SLSSpaceAddWindowsAndRemoveFromSpaces")
    else { return nil }

    let connection = unsafeBitCast(mainConnectionID, to: MainConnectionID.self)()
    let space = unsafeBitCast(spaceCreate, to: SpaceCreate.self)(connection, 1, 0)
    _ = unsafeBitCast(spaceSetAbsoluteLevel, to: SpaceSetAbsoluteLevel.self)(connection, space, lockScreenSpaceLevel)
    _ = unsafeBitCast(showSpaces, to: ShowSpaces.self)(connection, [space] as CFArray)

    let addWindowsToSpace = unsafeBitCast(addWindows, to: SpaceAddWindowsAndRemoveFromSpaces.self)
    return { window in
        // The final argument (7) is what SkyLightWindow passes; its meaning is undocumented.
        _ = addWindowsToSpace(connection, space, [window.windowNumber] as CFArray, 7)
    }
}
