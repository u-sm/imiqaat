# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The card can sit centered on the Lock Screen, under the clock, in the middle or above the login controls, as well as in a corner. Choose **Center High**, **Center** or **Center Low** under Position on the Card tab of Settings.
- The full card can show the middle and the last third of the night, for Qiyam and Tahajjud. Turn it on in Settings › Card.

### Fixed

- A reminder could be lost if the app updated its reminders at the moment one was due.

## [0.8.1] - 2026-10-29

Two reminder fixes.

### Fixed

- Reminders sent the old text after a change that kept their times, such as a new iqamah time or switching between 12- and 24-hour time. They're now sent again with the new text.
- The Sunrise reminder offers "At sunrise" instead of "At the adhan".

## [0.8.0] - 2026-10-29

Your card, your way: frosted glass, a compact style, any corner of the Lock Screen, larger text, and a countdown in the menu bar.

### Added

- On macOS 26 and later, the card is frosted glass over the Lock Screen wallpaper, like system widgets. With Reduce Transparency or Increase Contrast on, it's a solid dark card instead.
- A new **Card** tab in Settings:
  - **Style:** the full card, or a compact one with only the next prayer's countdown and time, and the Hijri date.
  - **Text size:** Standard, Large or Extra Large.
  - **Position** and **Margin:** any corner of the Lock Screen, and how far from the edges.
- **Show on Lock Screen** in the menu, on by default. Turn it off to keep only the menu-bar times.
- **Menu Bar Shows** in the menu: the next prayer's time, a countdown like the card's ("Asr in 1h 12m"), or the icon only.
- VoiceOver reads each of the card's rows as one item, such as "Asr, 15:55, iqamah 16:15, next prayer", and the countdown in words.

### Fixed

- The Settings window's tabs were blurry on macOS 26 and later. They're now in the window's toolbar, with icons, like other Mac apps' Settings, and the window's title names the open tab.

## [0.7.0] - 2026-10-29

Reminders: a notification at the prayers you choose, at the adhan or a few minutes before, and before the iqamah.

### Added

- Reminders: a notification at each prayer you choose, at the adhan or 5 to 30 minutes before, and optionally a few minutes before the iqamah. Set them on the new Reminders tab of Settings; iMiqaat asks to send notifications the first time you turn one on.

### Fixed

- City search results name the region where places share a name, such as Portland, OR and Portland, ME, so you can tell which one you're choosing. Cities chosen before keep their old name until chosen again.

## [0.6.0] - 2026-10-29

Times that match your mosque: a Settings window with per-prayer adjustments, iqamah times, Jumu'ah on Fridays, and the choice of a city instead of the Mac's location.

### Added

- A Settings window, opened with **Settings…** (⌘,) in the menu, for the calculation method, the Asr method and the high-latitude rule. The menu keeps quick access to the calculation method.
- Per-prayer adjustments of up to 30 minutes either way, on the Adjustments tab of Settings, to match a local mosque's timetable.
- Iqamah times on the Iqamah tab of Settings, a number of minutes after the adhan or at a fixed time. The card adds an iqamah column, and between the adhan and the iqamah it counts down to the iqamah.
- Jumu'ah on Fridays: Dhuhr shows as Jumu'ah on the card and in the menu bar, with optional khutbah and Jumu'ah times. Between the adhan and the khutbah, the card counts down to the khutbah.
- Choose a city in Settings instead of using the Mac's location. Its times are calculated and shown in its own time zone. City search sends what you type to Apple Maps.

### Changed

- The Asr method and the high-latitude rule moved from the menu to the Settings window. The menu keeps the calculation method.

## [0.5.0] - 2026-10-29

The app gets its look: an icon, a designed install window, Homebrew and a website. It also adds JAKIM and fixes the location going stale.

### Added

- An app icon, and a matching symbol next to the next prayer in the menu bar.
- A designed install window in the DMG, showing where to drag the app and how to open it the first time.
- Install with Homebrew: `brew install --cask u-sm/tap/imiqaat`.
- A website: <https://u-sm.github.io/imiqaat/>.
- JAKIM (Malaysia) as a calculation method, matching the official e-Solat timetables to within a minute or two.

### Fixed

- The location now stays current while the app runs. Before, it was fetched only at launch, so after a trip the times stayed those of the previous city, and if the first fix failed the times never appeared until the app was reopened.

## [0.1.0] - 2026-10-29

The first pre-release.

### Added

- A Lock Screen widget with the next prayer and a countdown, the Hijri date (Umm al-Qura, changing at Maghrib), and today's six times with the next one highlighted. It appears only while the screen is locked and updates every minute.
- A menu-bar item with the next prayer, and a menu to choose the calculation method (12 methods), the Asr method and the high-latitude rule.
- Times calculated offline with adhan-swift, from a location fetched once and kept on your Mac.
- A Launch at Login option.
- If a macOS update removes the private API the Lock Screen widget relies on, the app keeps working from the menu bar and says why the widget is missing.

[Unreleased]: https://github.com/u-sm/imiqaat/compare/v0.8.1...HEAD
[0.8.1]: https://github.com/u-sm/imiqaat/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/u-sm/imiqaat/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/u-sm/imiqaat/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/u-sm/imiqaat/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/u-sm/imiqaat/compare/v0.1.0...v0.5.0
[0.1.0]: https://github.com/u-sm/imiqaat/releases/tag/v0.1.0
