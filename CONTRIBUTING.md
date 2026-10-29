# Contributing to iMiqaat

Thanks for helping. This guide explains how changes get into the project.

By taking part, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before you start

- **Bugs and features:** open an issue first, using one of the templates. For anything bigger than a small fix, wait for agreement on the approach before writing code.
- **Scope:** check the [roadmap](docs/ROADMAP.md). Features outside v1.0 are tracked as issues and built only when there is demand.
- **Security issues:** don't open a public issue. Follow [SECURITY.md](SECURITY.md).

## Workflow

1. Fork the repository, then create a branch from `main`:

   | Prefix | Use for |
   |---|---|
   | `feat/` | A new feature |
   | `fix/` | A bug fix |
   | `docs/` | Documentation only |
   | `refactor/` | Code changes that don't change behaviour |
   | `test/` | Adding or fixing tests |
   | `chore/` | Tooling, CI and repository setup |

2. Make your changes in small, focused commits (see below).
3. Rebase on the latest `main` before opening the pull request.
4. Open a pull request, fill in the template, and link the issue (`Closes #123`).

`main` is protected: every change arrives through a pull request, CI must pass, and history stays linear. Pull requests are **rebase-merged**, so every commit in your branch lands on `main`. Shape your commits before asking for review.

## Commit messages

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<optional scope>): <summary>

<body: what changed and why>

<footer: Closes #123, BREAKING CHANGE: ...>
```

- **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Scopes:** `app`, `widget`, `overlay`, `prayerkit`, `ci`, `deps`
- **Summary:** imperative mood, lowercase, no full stop, 72 characters or fewer. Write "add high-latitude rule", not "Added high-latitude rule."
- **Body:** explain *why* the change is needed. The diff already shows *what*. Wrap at 72 characters.
- **One logical change per commit.** Each commit should build and pass the tests on its own.

Example:

```
feat(prayerkit): add high-latitude rule setting

Above roughly 48° latitude, Fajr and Isha can fall outside the night
or never occur in summer. Expose adhan-swift's high-latitude rules so
users in those regions get usable times.

Closes #42
```

## Code style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Formatting follows [`.editorconfig`](.editorconfig): 4-space indentation, LF line endings.
- Prefer platform APIs over new dependencies. A new dependency needs a reason in the pull request.
- New logic comes with tests. Prayer-time changes should be checked against a published timetable.

## Building

iMiqaat is a Swift package with no Xcode project. You need Swift 6, from the Command Line Tools (`xcode-select --install`) or Xcode.

```sh
swift build   # compile
swift test    # run the tests
scripts/bundle.sh && open .build/iMiqaat.app   # build and launch the app
```

Launch the app from its bundle, not with `swift run`: macOS asks for location permission only for an app with an `Info.plist`. `scripts/bundle.sh` builds, wraps the executable in `.build/iMiqaat.app` and signs it ad hoc; pass `-c release` for a release build. Quit the app with `pkill -x iMiqaat`.

With only the Command Line Tools, `swift test` may fail with "plugin for module 'TestingMacros' not found". The plugin is installed but not loaded; pass it explicitly:

```sh
swift test -Xswiftc -load-plugin-library \
  -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib
```

Tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`), because the Command Line Tools don't include XCTest.

To check a Lock Screen change, run the app, then lock the screen with **Control-Command-Q**.

### Images

The project's images are rendered by the Artwork tool and committed, so normal builds don't need to run it. After changing a drawing, regenerate its images and commit the result:

```sh
swift run Artwork dmg scripts/dmg         # the DMG window's background, laid out by scripts/dmg/settings.py
swift run Artwork icon Resources          # Resources/AppIcon.icns, from Sources/Artwork/AppIcon.swift
swift run Artwork screenshots docs/images # the README's icon, Lock Screen and menu-bar images, and the card's states, with sample data for Makkah
```

Screenshots never use your own location. The menu-bar symbol is drawn in code (`Sources/WidgetUI/MenuBarSymbol.swift`), so it needs no image file.

The Command Line Tools don't include SwiftUI's macro plugin, so `@State` and other SwiftUI macros won't compile. Keep view state in `ObservableObject` models so the project builds without Xcode.
