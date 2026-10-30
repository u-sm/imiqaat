#!/bin/sh
# Wraps the swift build executable in an .app bundle. CoreLocation won't ask
# for permission from a bare executable: it needs a bundle with a usage string.
# Usage: [VERSION=v1.2.3] scripts/bundle.sh [swift build options, e.g. -c release]
set -eu
cd "$(dirname "$0")/.."

swift build "$@"
bin="$(swift build "$@" --show-bin-path)"
app=.build/iMiqaat.app
version="${VERSION:-0.0.0}"
version="${version#v}"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/iMiqaat" "$app/Contents/MacOS/"
# Rendered by `swift run Artwork icon Resources`.
cp Resources/AppIcon.icns "$app/Contents/Resources/"
# Part of the adhan, cut from Beautiful adhan.ogg (CC0); see THIRD_PARTY_NOTICES.md.
cp Resources/adhan.aiff "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>io.github.u-sm.imiqaat</string>
    <key>CFBundleName</key>
    <string>iMiqaat</string>
    <key>CFBundleDisplayName</key>
    <string>iMiqaat</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleExecutable</key>
    <string>iMiqaat</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationUsageDescription</key>
    <string>iMiqaat uses your location only to calculate prayer times on this Mac, and never sends it anywhere.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>iMiqaat uses your location only to calculate prayer times on this Mac, and never sends it anywhere.</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "$app"
