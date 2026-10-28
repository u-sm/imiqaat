# Roadmap

iMiqaat is a macOS menu-bar app that shows today's salah times on the Lock Screen.

## Scope of v1.0

- The next prayer, with a live countdown.
- Today's times: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha.
- The Hijri date.
- Shown on the Lock Screen of the main display, and in the menu bar.
- Settings live in the menu-bar menu: calculation method, Asr madhab, and high-latitude rule.

**Not in v1.0:** iqamah times, adhan audio, notifications, multiple displays, custom placement, a settings window, a screensaver, auto-update, and interaction on the Lock Screen. Each one gets an issue when there is demand for it.

## How it works

### Lock Screen overlay

macOS has no public API for drawing on the Lock Screen. The app calls private SkyLight functions, using code adapted from [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) (MIT) in `Sources/iMiqaat/SkyLight.swift`:

1. Load `SkyLight.framework` with `dlopen`.
2. Use `SLSSpaceCreate` to make a private Space, and `SLSSpaceSetAbsoluteLevel` to raise it above the lock layer.
3. Show the Space with `SLSShowSpaces`.
4. Move the widget window into it with `SLSSpaceAddWindowsAndRemoveFromSpaces`.

Lock state comes from the distributed notifications `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked`.

**Consequences:**

- **No Mac App Store.** The app ships as a notarized download, with no App Sandbox.
- **It can break with any macOS update.** If the private functions are missing, the app still works from the menu bar.

### Prayer times

- **Calculation:** [adhan-swift](https://github.com/batoulapps/adhan-swift) (MIT) works offline. It covers every major calculation method, Asr madhab, high-latitude rules and per-prayer adjustments.
- **Location:** one CoreLocation fix, cached in `UserDefaults`. The only entitlement is `com.apple.security.personal-information.location`.
- **Hijri date:** `Calendar(identifier: .islamicUmmAlQura)`.
- **Staying current:** the card redraws every minute with `TimelineView(.everyMinute)` and recalculates from the current time in `TimeZone.autoupdatingCurrent`. That covers midnight, sleep and wake, and time-zone changes without separate observers.

## Layout

One Swift package, with no Xcode project. It builds with `swift build` using only the Command Line Tools:

```
Package.swift
Sources/
├── iMiqaat/        app: menu bar, Lock Screen window, SwiftUI widget view
└── PrayerKit/      adhan-swift wrapper, location cache (v0.2)
Tests/
└── PrayerKitTests/ tested with `swift test` (v0.2)
```

- The window code stays in the app target. It moves into its own module only if a second consumer appears, such as a screensaver.
- Location permission needs an `Info.plist`, which a bare executable doesn't have. The v0.2 location work adds a small script that wraps the executable in an `.app` bundle.
- The Command Line Tools lack SwiftUI's macro plugin, so views can't use `@State` until the project requires Xcode. Keep view state in plain `ObservableObject` models.

## Milestones

Each milestone is a GitHub milestone. Each line below is one pull request.

| Milestone | Pull requests |
|---|---|
| **v0.0 Foundations** | Repository documentation and templates |
| **v0.1 Spike** | Placeholder window visible on the Lock Screen · show and hide on lock and unlock |
| **v0.2 PrayerKit** | adhan-swift wrapper, with tests against published timetables (Makkah: Umm al-Qura; London: Moonsighting Committee) · CI: build and `swift test` on a macOS runner · location cache |
| **v0.3 Widget** | SwiftUI view: next prayer, countdown, today's list, Hijri date, kept current by a per-minute timeline |
| **v0.4 App** | Menu-bar extra with settings pickers · launch at login with `SMAppService.mainApp` · menu-bar-only fallback when SkyLight is unavailable |
| **v1.0 Release** | Signed and notarized DMG attached to a GitHub Release · README screenshots |

**v0.1 decides whether to continue.** If the overlay doesn't work on the current macOS, stop and rethink before building anything else.

## Releases

- Semantic version tags (`v0.1.0`), with GitHub Releases notes drawn from [CHANGELOG.md](../CHANGELOG.md).
- Pushing a tag runs `.github/workflows/release.yml`, which builds a universal DMG and publishes it as a GitHub Release. Pull requests that change the pipeline get a dry run that builds the DMG without publishing.
- Until v1.0, releases are ad-hoc signed pre-releases: macOS asks users to approve the app in Privacy & Security the first time they open it.
- The Developer ID certificate and notarization key will be stored in GitHub Secrets only, and are added at v1.0.

## Open decisions

- **Minimum macOS version:** set to macOS 13, the first with `MenuBarExtra` and `SMAppService`. The overlay is developed on macOS 27 and untested on older versions, so the minimum may rise once they are tried.
