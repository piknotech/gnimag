// swift-tools-version:5.1
import PackageDescription

// This Package.swift is only required for building via `swift build`, e.g. inside the makefile.
// It is not required during development inside Xcode.
// When adding or updating a (local) module, or a (remote) dependency, update this Package.swift accordingly to keep `make` intact.

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
            name: "identiti",
            dependencies: [
                "Common",
                "GameKit",
                "Geometry",
                "Image",
                "ImageAnalysisKit",
                "LoggingKit",
                "Tapping",
                "TestingTools",
            ],
            path: "Sources/Games/identiti"
        ),

        .target(
            name: "MrFlap",
            dependencies: [
                "Common",
                "GameKit",
                "Geometry",
                "Image",
                "ImageAnalysisKit",
                "LoggingKit",
                "Tapping",
                "TestingTools",
            ],
            path: "Sources/Games/MrFlap"
        ),

        // PRODUCTS
        .target(
            name: "gnimag",
            dependencies: [
                "Common",
                "Geometry",
                "identiti",
                "Image",
                "ImageAnalysisKit",
                "LoggingKit",
                "MrFlap",
                "Tapping",
                "TestingTools",
            ],
            path: "Sources/Products/gnimag"
        ),
    ]
)
