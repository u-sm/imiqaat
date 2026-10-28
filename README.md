<div align="center">

# iMiqaat

**Salah times on your Mac's Lock Screen.**

[![CI](https://github.com/u-sm/imiqaat/actions/workflows/ci.yml/badge.svg)](https://github.com/u-sm/imiqaat/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](#requirements)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138.svg?logo=swift&logoColor=white)](https://swift.org)
[![Status: pre-alpha](https://img.shields.io/badge/status-pre--alpha-orange.svg)](docs/ROADMAP.md)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

> [!WARNING]
> iMiqaat is in early development and there is no release yet. Follow the [roadmap](docs/ROADMAP.md) to see what is being built.

## Features

Planned for v1.0:

- 🕌 **The next prayer**, with a live countdown, right on the Lock Screen.
- 📅 **Today's times**: Fajr, Sunrise, Dhuhr, Asr, Maghrib and Isha.
- 🌙 **The Hijri date**, from the Umm al-Qura calendar.
- 🧭 **Your choice of calculation method, Asr madhab and high-latitude rule.**
- 📴 **Works offline.** Times are calculated on your Mac, and your location never leaves it.
- 🎛️ **Lives in the menu bar**, with no Dock icon.

## How it works

macOS has no public API for drawing on the Lock Screen. iMiqaat places its window in a private WindowServer Space above the lock layer, using a technique adapted from [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow). Prayer times are calculated locally with [adhan-swift](https://github.com/batoulapps/adhan-swift).

> [!IMPORTANT]
> Because iMiqaat relies on private macOS APIs:
> - It cannot be distributed through the Mac App Store. It ships as a signed, notarized download.
> - A macOS update could break the Lock Screen widget. If that happens, the menu-bar times keep working.

## Requirements

- macOS 13 or later (developed on macOS 27; older versions are untested)
- Swift 6 from the Command Line Tools or Xcode, to build from source

## Building from source

```sh
git clone https://github.com/u-sm/imiqaat.git
cd imiqaat
swift run
```

## Installation

There is no release yet. Signed, notarized builds will be published on the [Releases](https://github.com/u-sm/imiqaat/releases) page.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for the plan and milestones.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and commit conventions. This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).

To report a security issue, follow [SECURITY.md](SECURITY.md) and do not open a public issue.

## Acknowledgements

- [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) by Lakr Aream (MIT), for the Lock Screen window technique, adapted in `Sources/iMiqaat/SkyLight.swift`.
- [adhan-swift](https://github.com/batoulapps/adhan-swift) by Batoul Apps (MIT), for prayer-time calculation.

## License

iMiqaat is released under the [MIT License](LICENSE).
