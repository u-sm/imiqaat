# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An app icon, and a matching symbol next to the next prayer in the menu bar.
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

[Unreleased]: https://github.com/u-sm/imiqaat/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/u-sm/imiqaat/releases/tag/v0.1.0
