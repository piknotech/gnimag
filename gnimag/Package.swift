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
        .executable(name: "gnimag", targets: ["gnimag-cli"]),
    ],
    dependencies: [
        /// A Swift library that uses the Accelerate framework to provide high-performance functions for matrix math, digital signal processing, and image manipulation.
        .package(url: "https://github.com/Jounce/Surge", .upToNextMajor(from: "2.3.0")),

        /// Beautiful charts for iOS/tvOS/OSX! The Apple side of the crossplatform MPAndroidChart.
        .package(url: "https://github.com/danielgindi/Charts", .upToNextMajor(from: "3.4.0")),

        .package(url: "https://github.com/armadsen/ORSSerialPort", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        // BASE
        .target(
            name: "Common",
            path: "Modules/Base/Common"
        ),

        .target(
            name: "Image",
            dependencies: [
                "Common"
            ],
            path: "Modules/Base/Image"
        ),

        .target(
            name: "Tapping",
            dependencies: [
                "Common"
            ],
            path: "Modules/Base/Tapping"
        ),

        .target(
            name: "Geometry",
            dependencies: [
                "Common"
            ],
            path: "Modules/Base/Geometry"
        ),

        .target(
            name: "ImageAnalysisKit",
            dependencies: [
                "Common",
                "Image",
                "TestingTools"
            ],
            path: "Modules/Base/ImageAnalysisKit"
        ),

        .target(
            name: "GameKit",
            dependencies: [
                "Common",
                "TestingTools",
                "Surge"
            ],
            path: "Modules/Base/GameKit"
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
            path: "Modules/Debug/TestingTools"
        ),

        .target(
            name: "LoggingKit",
            dependencies: [
                "Common",
                "GameKit",
                "TestingTools",
            ],
            path: "Modules/Debug/LoggingKit"
        ),

        // GAMES
        .target(
            name: "FlowFree",
            dependencies: allLibraries + [
                "FlowFreeC"
            ],
            path: "Modules/Games/FlowFree",
            exclude: ["FlowFreeC"]
        ),

        // C code used in FlowFree. Must be in a separate target due to swift build limitations
        .target(
            name: "FlowFreeC",
            path: "Modules/Games/FlowFree/FlowFreeC"
        ),

        .target(
            name: "MrFlap",
            dependencies: allLibraries,
            path: "Modules/Games/MrFlap"
        ),

        .target(
            name: "YesNoMathGames",
            dependencies: allLibraries,
            path: "Modules/Games/YesNoMathGames"
        ),

        // EXECUTABLES
        .target(
            name: "gnimag-cli",
            dependencies: allLibraries + [
                "FlowFree",
                "MrFlap",
                "YesNoMathGames",
                "ORSSerial"
            ],
            path: "Modules/Executables/gnimag-cli"
        ),
    ]
)
