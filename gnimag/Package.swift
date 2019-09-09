// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "gnimag",
    products: [
    ],
    dependencies: [
        /// A Swift library that uses the Accelerate framework to provide high-performance functions for matrix math, digital signal processing, and image manipulation.
        .package(url: "https://github.com/mattt/Surge", .upToNextMajor(from: "2.0.0")),

        /// Beautiful charts for iOS/tvOS/OSX! The Apple side of the crossplatform MPAndroidChart.
        .package(url: "https://github.com/danielgindi/Charts", .upToNextMajor(from: "3.3.0")),

        /// Handy Swift features that didn't make it into the Swift standard library.
        .package(url: "https://github.com/Flinesoft/HandySwift", .upToNextMajor(from: "3.1.0"))
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
            name: "Common",
            dependencies: [
                "HandySwift"
            ],
            path: "Sources/Base/Common"
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
