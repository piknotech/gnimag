// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "gnimag",
    products: [
        // .executable(name: "MacCLI", targets: ["MacCLI"])
    ],
    dependencies: [
        /// A Swift library that uses the Accelerate framework to provide high-performance functions for matrix math, digital signal processing, and image manipulation.
        .package(url: "https://github.com/mattt/Surge", .upToNextMajor(from: "2.0.0")),

        /// Beautiful charts for iOS/tvOS/OSX! The Apple side of the crossplatform MPAndroidChart.
        .package(url: "https://github.com/danielgindi/Charts", .upToNextMajor(from: "3.3.0"))
    ],

    targets: [
        .target(
            name: "GameKit",
            dependencies: [
                "Surge"
            ],
            path: "Sources/Base/GameKit"
        ),

        .target(
            name: "MacTestingTools",
            dependencies: [
                "Charts"
            ],
            path: "Sources/Mac/MacTestingTools"
        )
    ]
)
