// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "iMiqaat",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(name: "iMiqaat"),
        .target(
            name: "PrayerKit",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(
            name: "PrayerKitTests",
            dependencies: ["PrayerKit", .product(name: "Adhan", package: "adhan-swift")]
        ),
    ]
)
