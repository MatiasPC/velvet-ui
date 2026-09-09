// swift-tools-version: 6.0
import PackageDescription

// Tools 6.0 is required only to spell `.iOS(.v18)` / `.macOS(.v15)`. The language
// mode stays at v5 on purpose: moving to Swift 6 strict concurrency is its own
// migration, not a side effect of raising the deployment target.
let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "DesignSystem",
            path: "Sources/DesignSystem",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Tests/DesignSystemTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
