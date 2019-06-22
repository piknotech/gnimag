// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gnimag",
    platforms: [.macOS(.v10_14)],
    targets: [
        .target(
            name: "MacCLI",
            dependencies: [
                "MrFlap"
            ]
        ),
        .target(
            name: "MrFlap",
            path: "Sources/Games/MrFlap"
        )
    ]
)
