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
            dependencies: ["MacTestingTools", "MrFlap", "ImageInput", "Tapping"],
            path: "Sources/Mac/MacCLI"
        ),
        .target(
            name: "MacTestingTools",
            dependencies: ["ImageInput"],
            path: "Sources/Mac/MacTestingTools"
        ),
        .target(
            name: "MrFlap",
            dependencies: ["ImageInput", "Tapping", "ImageAnalysisKit", "GameKit"],
            path: "Sources/Games/MrFlap"
        ),
        .target(
            name: "GameKit",
            dependencies: ["Surge"],
            path: "Sources/Base/GameKit"
        ),
        .target(
            name: "ImageInput",
            path: "Sources/Base/ImageInput"
        ),
        .target(
            name: "Tapping",
            path: "Sources/Base/Tapping"
        ),
        .target(
            name: "ImageAnalysisKit",
            dependencies: ["ImageInput"],
            path: "Sources/Base/ImageAnalysisKit"
        )
    ]
)
