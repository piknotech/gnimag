// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gnimag",
    platforms: [.macOS(.v10_14)],
    targets: [
        .target(
            name: "MacCLI",
            dependencies: ["MrFlap", "Input", "Output"]
        ),
        .target(
            name: "MrFlap",
            dependencies: ["Input", "Output", "ImageAnalysis", "Regression"],
            path: "Sources/Games/MrFlap"
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
        ),
        .target(
            name: "Regression",
            path: "Sources/Libraries/Regression"
        ),
    ]
)
