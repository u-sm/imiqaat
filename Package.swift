// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iMiqaat",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "iMiqaat",
            dependencies: ["PrayerKit", "WidgetUI", .product(name: "Adhan", package: "adhan-swift")]
        ),
        .target(
            name: "PrayerKit",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .target(
            name: "WidgetUI",
            dependencies: ["PrayerKit", .product(name: "Adhan", package: "adhan-swift")]
        ),
        // Renders the screenshots: swift run Artwork screenshots <output dir>
        .executableTarget(
            name: "Artwork",
            dependencies: ["PrayerKit", "WidgetUI", .product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(
            name: "PrayerKitTests",
            dependencies: ["PrayerKit", "WidgetUI", .product(name: "Adhan", package: "adhan-swift")]
        ),
    ]
)
