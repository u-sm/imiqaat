# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project documentation: README, roadmap, contributing guide, code of conduct and security policy.
- Issue and pull request templates.
- A placeholder widget on the Lock Screen, proving the private SkyLight overlay works. It appears only while the screen is locked.
- PrayerKit: today's prayer times, the next prayer and the Hijri date for a location, calculated offline with adhan-swift.
- The Mac's location, fetched once and cached so the app works offline. The Lock Screen card shows the next prayer, or explains how to allow location access.
- `scripts/bundle.sh`, which builds the app as a signed `.app` bundle.
- The Lock Screen widget: the next prayer with a countdown, the Hijri date, and today's six times with the next one highlighted. It updates every minute.
- A menu-bar item showing the next prayer, with a menu to choose the calculation method, Asr method and high-latitude rule.
