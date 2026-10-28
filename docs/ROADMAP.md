# Roadmap

imiqaat is a macOS menu-bar app that shows today's salah times on the Lock Screen.

## Scope of v1.0

- The next prayer, with a live countdown.
- Today's times: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha.
- The Hijri date.
- Shown on the Lock Screen of the main display, and in the menu bar.
- Settings live in the menu-bar menu: calculation method, Asr madhab, and high-latitude rule.

**Not in v1.0:** iqamah times, adhan audio, notifications, multiple displays, custom placement, a settings window, a screensaver, auto-update, and interaction on the Lock Screen. Each one gets an issue when there is demand for it.

## How it works

### Lock Screen overlay

macOS has no public API for drawing on the Lock Screen. The app uses [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) (Swift package, MIT), which calls private SkyLight functions:

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
- **When to recompute:** at a day change (`NSCalendarDayChanged`), a clock or time-zone change, and wake from sleep.
- **Countdown:** `TimelineView(.periodic(from: .now, by: 1))`.

## Layout

A single Xcode app target, plus one local Swift package so the maths can be tested with `swift test`:

```
imiqaat/
├── App/            menu bar, Lock Screen window, SwiftUI widget view
└── PrayerKit/      Swift package: adhan-swift wrapper, location cache, tests
```

The window code stays in the app target. It moves into its own module only if a second consumer appears, such as a screensaver.

## Milestones

Each milestone is a GitHub milestone. Each line below is one pull request.

| Milestone | Pull requests |
|---|---|
| **v0.0 Foundations** | Repository documentation and templates |
| **v0.1 Spike** | SkyLightWindow "hello" window visible on the Lock Screen · show and hide on lock and unlock |
| **v0.2 PrayerKit** | adhan-swift wrapper, with tests against published timetables (Makkah: Umm al-Qura; London: Moonsighting Committee) · CI: build and `swift test` on a macOS runner · location cache |
| **v0.3 Widget** | SwiftUI view: next prayer, countdown, today's list, Hijri date · recompute on day, clock and wake changes |
| **v0.4 App** | Menu-bar extra with settings pickers · launch at login with `SMAppService.mainApp` · menu-bar-only fallback when SkyLight is unavailable |
| **v1.0 Release** | Signed and notarized DMG attached to a GitHub Release · README screenshots |

**v0.1 decides whether to continue.** If the overlay doesn't work on the current macOS, stop and rethink before building anything else.

## Releases

- Semantic version tags (`v0.1.0`), with GitHub Releases notes drawn from [CHANGELOG.md](../CHANGELOG.md).
- The Developer ID certificate and notarization key are stored in GitHub Secrets only, and are added at v1.0. Until then, contributors build with ad-hoc signing.

## Open decisions

- **Minimum macOS version:** whatever SkyLightWindow supports, settled during v0.1.
