//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Input

/// ContourDetectionViaEquidistantRays uses information about the inside of a shape to detect its boundaries.
/// A starting point INSIDE the shape is used. Then, equidistant rays are cast in all directions. For each ray, a color match sequence is used to detect when the outside of the shape has been reached.
/// These points on the edge will then be returned as the contour of the shape.

public enum ContourDetectionViaEquidistantRays {
    // MARK: Arguments
    public struct Arguments {
        /// A pixel INSIDE the shape from where the rays are cast.
        public let detectionCenter: Pixel

        /// The number of rays that are cast.
        public let numberOfRays: Int

        /// The speed of the rays. 1 means that each pixel will be checked.
        public let raySpeed: Int

        /// The sequence that defines the inside and outside of the shape. This means:
        /// The sequence defines the way from the center pixel to the outside. All colors in this sequence are processed. When the LAST color in the sequence has been matched, the outside of the shape has been found.
        public let colorSequence: ColorMatchSequence

        /// Describes what happens when the sequence cannot be completed for a ray.
        public let rayHasHitBoundsMode: RayHasHitBoundsMode

        public enum RayHasHitBoundsMode {
            /// Ignore this ray and use the information from the other rays.
            case ignore

            /// Use the point where the ray has hit the bounds as outside of the shape. This means, the shape will (partly) be defined by the bounds of the image.
            case treatBoundsAsContour

            /// Fail the operation and return an error.
            case fail
        }

        /// Default initializer.
        public init(detectionCenter: Pixel, numberOfRays: Int, raySpeed: Int, colorSequence: ColorMatchSequence, rayHasHitBoundsMode: RayHasHitBoundsMode) {
            self.detectionCenter = detectionCenter
            self.numberOfRays = numberOfRays
            self.raySpeed = raySpeed
            self.colorSequence = colorSequence
            self.rayHasHitBoundsMode = rayHasHitBoundsMode
        }
    }

    // MARK: Result
    public enum Error: Swift.Error {
        /// This error can only occur when "rayHasHitBoundsMode" was set to ".fail".
        case hitImageBounds
    }

    // MARK: Algorithm
    /// Detect a contour inside the image using the given arguments.
    public static func detectContour(in image: Image, arguments: Arguments) -> Result<[Pixel], ContourDetectionViaEquidistantRays.Error> {
        var contour = [Pixel]()

        for i in 0 ..< arguments.numberOfRays {
            // Construct StraightPath in correct direction
            let angle = 2 * .pi * Double(i) / Double(arguments.numberOfRays)
            var path: PixelPath = StraightPath(start: arguments.detectionCenter, angle: angle, bounds: image.bounds, speed: Double(arguments.raySpeed))

            // Run through the path until the ColorMatchSequence is fulfilled
            let result = image.follow(path: &path, untilFulfillingSequence: arguments.colorSequence)

            switch result {
            case let .fulfilled(previousPixel: pixel, fulfilledPixel: backup):
                contour.append(pixel ?? backup) // Found the pixel on the shape edge as desired

            case let .notFulfilled(lastPixelOfPath: pixel, _):
                // Sequence was not fulfilled --> ray has hit the bounds
                switch arguments.rayHasHitBoundsMode {
                case .fail: return .failure(.hitImageBounds)
                case .ignore: continue
                case .treatBoundsAsContour: contour.append(pixel!)
                }
            }

        }

        return .success(contour)
    }
}

extension Image {
    /// Detect a contour inside the image using the given arguments.
    public func detectContourViaEquidistantRays(arguments: ContourDetectionViaEquidistantRays.Arguments) -> Result<[Pixel], ContourDetectionViaEquidistantRays.Error> {
        ContourDetectionViaEquidistantRays.detectContour(in: self, arguments: arguments)
    }
}
