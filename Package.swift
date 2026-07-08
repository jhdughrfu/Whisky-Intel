// swift-tools-version: 5.8
// Whisky Intel Edition — SPM Build (no Xcode required)

import PackageDescription

let package = Package(
    name: "Whisky",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Whisky", targets: ["Whisky"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftPackageIndex/SemanticVersion.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "WhiskyKit",
            dependencies: ["SemanticVersion"],
            path: "WhiskyKit/Sources/WhiskyKit",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        ),
        .executableTarget(
            name: "Whisky",
            dependencies: ["WhiskyKit", "SemanticVersion"],
            path: "Whisky",
            exclude: [
                "Assets.xcassets",
                "Preview Content",
                "Info.plist",
                "Whisky.entitlements",
                "Localizable.xcstrings"
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        )
    ]
)
