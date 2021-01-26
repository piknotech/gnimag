//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

/// RayShooter uses information about the inside of a shape to detect its boundaries.
/// A starting point INSIDE the shape is used. Then, equidistant rays are cast in all directions. For each ray, a color match sequence is used to detect when the outside of the shape has been reached.
/// These (inner) points on the edge will then be returned as the contour of the shape.
public enum RayShooter {
    public enum RayHasHitBoundsMode {
        /// Ignore this ray and use the information from the other rays.
        case ignoreRay

        /// Use the point where the ray has hit the bounds as outside of the shape. This means, the shape will (partly) be defined by the bounds of the image.
        case treatBoundsAsContour

        /// Fail the operation and return an error.
        case fail
    }

    /// Detect a contour inside the image using the given parameters.
    /// Can return `nil` only if `whenRayHitsBounds` = `.fail`.
    /// - Parameters:
    ///     - image: The image.
    ///     - center: The point from which the rays are cast.
    ///     - numRays: Number of equidistant rays which are shot. Has a linear effect on run-time.
    ///     - colorSequence: This sequence has to be fulfilled for each ray to detect a contour. This means: All colors in this sequence are processed. When the LAST color in the sequence has been matched, the outside of the shape has been found – the previous pixel will be added to the contour of the shape.
    ///     - raySpeed: The speed with which the rays advance. Has a linear effect on run-time.
    ///     - whenRayHitsBounds: Defines what happens when a ray hits the image bounds without fulfilling the color sequence.
    /// - Returns: The found contour points. This array has at most `numRays` entries. Can return `nil` only if `whenRayHitsBounds` = `.fail`.
    public static func findContour(
        in image: Image,
        center detectionCenter: Pixel,
        numRays: Int,
        colorSequence: ColorMatchSequence,
        raySpeed: Int = 1,
        whenRayHitsBounds: RayHasHitBoundsMode = .ignoreRay
    ) -> [Pixel]? {
        var contour = [Pixel]()

        for i in 0 ..< numRays {
            // Construct StraightPath in correct direction
            let angle = 2 * .pi * CGFloat(i) / CGFloat(numRays)
            let path = StraightPath(start: detectionCenter, angle: Angle(angle), bounds: image.bounds, speed: CGFloat(raySpeed))

            // Run through the path until the ColorMatchSequence is fulfilled
            let result = image.follow(path: path, untilFulfillingSequence: colorSequence)

            switch result {
            case let .fulfilled(previousPixel: pixel, _):
                if let pixel = pixel { contour.append(pixel) }

            case let .notFulfilled(lastPixelOfPath: pixel, _):
                // Sequence was not fulfilled --> ray has hit the bounds
                switch whenRayHitsBounds {
                case .fail:
                    return nil
                case .ignoreRay:
                    continue
                case .treatBoundsAsContour:
                    if let pixel = pixel { contour.append(pixel) }
                }
            }

        }

        return contour
    }
}
