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
            dependencies: ["MrFlap", "ImageInput", "Tapping"]
        ),
        .target(
            name: "MrFlap",
            dependencies: ["ImageInput", "Tapping", "ImageAnalysisKit", "GameKit"],
            path: "Sources/Games/MrFlap"
        ),
        .target(
            name: "GameKit",
            dependencies: ["Surge"],
            path: "Sources/Libraries/GameKit"
        ),
        .target(
            name: "ImageInput",
            path: "Sources/Libraries/ImageInput"
        ),
        .target(
            name: "Tapping",
            path: "Sources/Libraries/Tapping"
        ),
        .target(
            name: "ImageAnalysisKit",
            dependencies: ["ImageInput"],
            path: "Sources/Libraries/ImageAnalysisKit"
        )
    ]
)
