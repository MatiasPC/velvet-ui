// swift-tools-version: 6.0
import PackageDescription

// Tools 6.0 is required only to spell `.iOS(.v18)` / `.macOS(.v15)`. The language
// mode stays at v5 on purpose: moving to Swift 6 strict concurrency is its own
// migration, not a side effect of raising the deployment target.
let package = Package(
    name: "VelvetUI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "VelvetUI",
            targets: ["VelvetUI"]
        )
    ],
    targets: [
        .target(
            name: "VelvetUI",
            path: "Sources/VelvetUI",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VelvetUITests",
            dependencies: ["VelvetUI"],
            path: "Tests/VelvetUITests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
