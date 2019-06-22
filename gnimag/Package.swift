// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gnimag",
    platforms: [.macOS(.v10_14)],
    dependencies: [
        .package(url: "https://github.com/mattt/Surge", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(
            name: "MacCLI",
            dependencies: ["MrFlap", "Input", "Output"]
        ),
        .target(
            name: "MrFlap",
            dependencies: ["Input", "Output", "ImageAnalysis", "GameKit"],
            path: "Sources/Games/MrFlap"
        ),
        .target(
            name: "GameKit",
            dependencies: ["Surge"],
            path: "Sources/Libraries/GameKit"
        ),
        .target(
            name: "Input",
            path: "Sources/Libraries/Input"
        ),
        .target(
            name: "Output",
            path: "Sources/Libraries/Output"
        ),
        .target(
            name: "ImageAnalysis",
            dependencies: ["Input"],
            path: "Sources/Libraries/ImageAnalysis"
        )
    ]
)
