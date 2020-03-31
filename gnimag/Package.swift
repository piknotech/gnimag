// swift-tools-version:5.1
import PackageDescription

// This Package.swift is only required for building via `swift build`, e.g. inside the makefile.
// It is not required during development inside Xcode.
// When adding or updating a (local) module, or a (remote) dependency, update this Package.swift accordingly to keep `make` intact.

/// All non-game libraries, i.e. base + debug libraries.
let allLibraries: [Target.Dependency] = [
    "Common",
    "GameKit",
    "Geometry",
    "Image",
    "ImageAnalysisKit",
    "LoggingKit",
    "Tapping",
    "TestingTools"
]

let package = Package(
    name: "gnimag",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "gnimag", targets: ["gnimag"]),
    ],
    dependencies: [
        /// A Swift library that uses the Accelerate framework to provide high-performance functions for matrix math, digital signal processing, and image manipulation.
        .package(url: "https://github.com/Jounce/Surge", .upToNextMajor(from: "2.3.0")),

        /// Beautiful charts for iOS/tvOS/OSX! The Apple side of the crossplatform MPAndroidChart.
        .package(url: "https://github.com/danielgindi/Charts", .upToNextMajor(from: "3.4.0")),

        /// A Swift framework for shell scripting.
        .package(url: "https://github.com/kareman/SwiftShell", .upToNextMajor(from: "5.0.1")),
    ],
    targets: [
        // BASE
        .target(
            name: "Common",
            path: "Sources/Base/Common"
        ),

        .target(
            name: "Image",
            dependencies: [
                "Common"
            ],
            path: "Sources/Base/Image"
        ),

        .target(
            name: "Tapping",
            dependencies: [
                "Common"
            ],
            path: "Sources/Base/Tapping"
        ),

        .target(
            name: "Geometry",
            dependencies: [
                "Common"
            ],
            path: "Sources/Base/Geometry"
        ),

        .target(
            name: "ImageAnalysisKit",
            dependencies: [
                "Common",
                "Image",
                "TestingTools"
            ],
            path: "Sources/Base/ImageAnalysisKit"
        ),

        .target(
            name: "GameKit",
            dependencies: [
                "Common",
                "TestingTools",
                "Surge"
            ],
            path: "Sources/Base/GameKit"
        ),

        // DEBUG
        .target(
            name: "TestingTools",
            dependencies: [
                "Charts",
                "Common",
                "Geometry",
                "Image"
            ],
            path: "Sources/Debug/TestingTools"
        ),

        .target(
            name: "LoggingKit",
            dependencies: [
                "Common",
                "GameKit",
                "TestingTools",
            ],
            path: "Sources/Debug/LoggingKit"
        ),

        // GAMES
        .target(
            name: "FlowFree",
            dependencies: allLibraries + [
                "SwiftShell"
            ],
            path: "Sources/Games/FlowFree"
        ),

        .target(
            name: "identiti",
            dependencies: allLibraries,
            path: "Sources/Games/identiti"
        ),

        .target(
            name: "MrFlap",
            dependencies: allLibraries,
            path: "Sources/Games/MrFlap"
        ),

        // PRODUCTS
        .target(
            name: "gnimag",
            dependencies: allLibraries + [
                "FlowFree",
                "identiti",
                "MrFlap"
            ],
            path: "Sources/Products/gnimag"
        ),
    ]
)
