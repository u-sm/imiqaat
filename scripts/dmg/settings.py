# dmgbuild settings for the install window. Run from the repository root:
#   dmgbuild -s scripts/dmg/settings.py -D app=.build/iMiqaat.app iMiqaat iMiqaat.dmg
# dmgbuild writes Finder's window layout itself, so it works without a logged-in Finder,
# as on CI. The background is rendered by `swift run Artwork dmg scripts/dmg`.

app = defines["app"]  # noqa: F821, dmgbuild provides `defines`

format = "ULFO"
files = [app]
symlinks = {"Applications": "/Applications"}
icon = app + "/Contents/Resources/AppIcon.icns"

background = "scripts/dmg/background.tiff"
window_rect = ((200, 120), (660, 400))
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
default_view = "icon-view"
icon_size = 128
text_size = 13
# Icon centres, matching the arrow drawn in Sources/Artwork/DMGBackground.swift.
icon_locations = {"iMiqaat.app": (165, 190), "Applications": (495, 190)}
