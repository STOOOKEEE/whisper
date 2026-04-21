// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SuperWhisper",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SuperWhisper",
            dependencies: [
                .product(name: "SwiftWhisper", package: "SwiftWhisper")
            ]
        ),
    ]
)
