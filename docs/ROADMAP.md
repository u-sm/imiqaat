# Roadmap

iMiqaat is a macOS menu-bar app that shows today's salah times on the Lock Screen.

## Shipped in 0.1.0

- The next prayer, with a live countdown, on the Lock Screen of the main display.
- Today's times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) and the Umm al-Qura Hijri date, which changes at Maghrib.
- A menu-bar item with the next prayer, and a menu for the calculation method, Asr method and high-latitude rule.
- Launch at Login, and a menu-bar-only fallback if a macOS update removes the private Lock Screen API.

## Not planned

These have been considered and set aside for now: mosque timetable import, custom Fajr and Isha angles, Qibla direction, calendar export, travel reminders, multiple displays, a screensaver, and interacting with the card on the Lock Screen. Open an issue if you need one of them.

## How it works

### Lock Screen overlay

macOS has no public API for drawing on the Lock Screen. The app calls private SkyLight functions, using code adapted from [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) (MIT) in `Sources/iMiqaat/SkyLight.swift`:

1. Load `SkyLight.framework` with `dlopen`.
2. Use `SLSSpaceCreate` to make a private Space, and `SLSSpaceSetAbsoluteLevel` to raise it above the lock layer.
3. Show the Space with `SLSShowSpaces`.
4. Move the widget window into it with `SLSSpaceAddWindowsAndRemoveFromSpaces`.

Lock state comes from the distributed notifications `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked`.

**Consequences:**

- **No Mac App Store.** The app ships as a direct download, with no App Sandbox: ad-hoc signed for now, notarized from v1.0.
- **It can break with any macOS update.** If the private functions are missing, the app still works from the menu bar.

### Prayer times

- **Calculation:** [adhan-swift](https://github.com/batoulapps/adhan-swift) (MIT) works offline. It covers every major calculation method, Asr madhab, high-latitude rules and per-prayer adjustments.
- **Location:** CoreLocation's significant-change updates, with the latest fix cached in `UserDefaults`. The only entitlement is `com.apple.security.personal-information.location`.
- **Hijri date:** `Calendar(identifier: .islamicUmmAlQura)`.
- **Staying current:** the card redraws every minute with `TimelineView(.everyMinute)` and recalculates from the current time in `TimeZone.autoupdatingCurrent`. That covers midnight, sleep and wake, and time-zone changes without separate observers.

## Layout

One Swift package, with no Xcode project. It builds with `swift build` using only the Command Line Tools:

```
Package.swift
Sources/
├── iMiqaat/        app: menu bar, Lock Screen window
├── PrayerKit/      adhan-swift wrapper, location cache (v0.2)
├── WidgetUI/       the SwiftUI card, shared by the app and Artwork
└── Artwork/        renders the project's images from the real views (#23)
Tests/
└── PrayerKitTests/ tested with `swift test` (v0.2)
```

- The card is drawn from plain values (`CardView(.times(schedule, now:))`), so Artwork can render it with fixed sample data, and a WidgetKit widget (#51) can reuse it later. The app wraps it in `LiveCardView`, which follows the location and the clock.
- Location permission needs an `Info.plist`, which a bare executable doesn't have. The v0.2 location work adds a small script that wraps the executable in an `.app` bundle.
- The Command Line Tools lack SwiftUI's macro plugin, so views can't use `@State` until the project requires Xcode. Keep view state in plain `ObservableObject` models.

## Milestones

Each milestone is a GitHub milestone, and each of its issues becomes one pull request. Milestone vX.Y ships as release vX.Y.0.

### Done

| Milestone | What it delivered |
|---|---|
| **v0.0 Foundations** | Repository documentation and templates |
| **v0.1 Spike** | Proof that a window can be shown on the Lock Screen, only while locked |
| **v0.2 PrayerKit** | adhan-swift wrapper tested against Umm al-Qura's published timetable · CI · location cache |
| **v0.3 Widget** | The Lock Screen card: next prayer, countdown, today's times, Hijri date, kept current every minute |
| **v0.4 App** | Menu-bar item with calculation settings · Launch at Login · menu-bar-only fallback |
| **v0.5 Identity** | Artwork tool · app icon and menu-bar symbol · DMG install window · README screenshots · website · Homebrew tap · release-notes fix · location kept current · JAKIM method |
| **v0.6 Accurate times** | Settings window · per-prayer adjustments · choose a city · iqamah times · Jumu'ah · audit fixes: one tested time format, city search feedback |
| **v0.7 Reminders** | Notifications at the adhan, before it and before the iqamah · audit fixes: region in city search results, a tested countdown order, no release without changelog notes |
| **v0.8 Widget options** | Glass card · compact style · text size · any corner and margin · hide on Lock Screen · menu-bar countdown · VoiceOver labels · Settings tabs in the toolbar |

v0.0–v0.4 were released as the **0.1.0** pre-release, v0.5 as **0.5.0**, v0.6 as **0.6.0**, v0.7 as **0.7.0** and v0.8 as **0.8.0**, followed by **0.8.1** with two reminder fixes.

### Next

| Milestone | Issues | Why in this order |
|---|---|---|
| **v0.9 Islamic calendar** | Hijri adjustment (#32) · Sunnah times (#45) · forbidden times (#46) · Ramadan mode (#47) · upcoming Islamic dates (#48) · moved from v0.8: adhan audio (#37), pause media (#38), and the location-rule tidy-up for new contributors (#77) | Depends on reminders (#36). The Hijri adjustment comes first, because Ramadan mode and Islamic dates use it. |
| **v0.10 Languages** | Localization with Arabic (#49) · more languages (#50) | Last, so translators work on settled text instead of chasing changes. |
| **v1.0 Release** | Developer ID signing and notarization | Waiting on an Apple Developer account. Sparkle auto-updates follow it, because updates need a stable signing identity. |

### Later

- **Desktop and Notification Center widget** (#51): blocked until the project has an Xcode project and a Developer ID, which WidgetKit extensions and App Groups require.

## Releases

- Semantic version tags (`v0.1.0`), with GitHub Releases notes drawn from [CHANGELOG.md](../CHANGELOG.md). Milestone vX.Y ships as vX.Y.0, so the next release is 0.9.0.
- Pushing a tag runs `.github/workflows/release.yml`, which builds a universal DMG and publishes it as a GitHub Release. Pull requests that change the pipeline get a dry run that builds the DMG without publishing.
- Until v1.0, releases are ad-hoc signed pre-releases: macOS asks users to approve the app in Privacy & Security the first time they open it.
- The Developer ID certificate and notarization key will be stored in GitHub Secrets only, and are added at v1.0.

## Open decisions

- **Minimum macOS version:** set to macOS 13, the first with `SMAppService`, which Launch at Login uses. The overlay is developed on macOS 27 and untested on older versions, so the minimum may rise once they are tried.
