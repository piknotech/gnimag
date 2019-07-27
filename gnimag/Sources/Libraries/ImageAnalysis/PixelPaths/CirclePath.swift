//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Input

/// A PixelPath that consists of equidistant pixels on a circle. The circle is traversed exactly once.
/// Only pixels inside the given bounds are traversed.

public struct CirclePath: PixelPath {
    /// Possible ways to procced with pixels that are on the circle but outside bounds.
    public enum PixelsOutsideBoundsMode {
        case skip
        case stopPath
    }

    // MARK: Properties

    /// The circle that is described by this path.
    public let circle: Circle

    /// The number of pixels on the circle.
    public let numberOfPixels: Int

    /// The angle of the first pixel on the circle.
    public let startAngle: Double

    /// The bounds in which the walk should be performed.
    public let bounds: Bounds

    /// If the circle is not fully inside bounds, pixels are either skipped or the path is stopped, depending on pixelsOutsideBoundsMode.
    public let pixelsOutsideBoundsMode: PixelsOutsideBoundsMode

    // MARK: PixelPath

    /// The number of pixels that already have been traversed.
    private var currentStep = 0

    /// Return the next pixels on the path.
    public mutating func next(_ num: Int) -> [Pixel] {
        var result = [Pixel]()

        // While loop stops either after "num" pixels have been accumulated or all pixels on the circle have been traversed
        while result.count < num && currentStep < numberOfPixels {
            if let next = next() {
                result.append(next)
            } else {
                // Either skip pixel or stop path
                switch pixelsOutsideBoundsMode {
                case .skip: continue
                case .stopPath: break
                }
            }
        }

        return result
    }

    /// Return the single next pixel on the path.
    /// If the bounds are surpassed, return nil.
    private mutating func next() -> Pixel? {
        let delta = 2 * .pi / Double(numberOfPixels)
        let angle = startAngle + Double(currentStep) * delta

        let pixel = circle.pixel(at: angle)
        currentStep += 1

        if bounds.contains(pixel) {
            return pixel
        } else {
            return nil
        }
    }
}

// MARK: Equidistant Pixels
extension CirclePath {
    /// Return "numberOfPixels" equidistant pixels on a circle.
    public static func equidistantPixels(on circle: Circle, numberOfPixels: Int, startAngle: Double = 0) -> [Pixel] {
        let delta = 2 * .pi / Double(numberOfPixels)

        return (0 ..< numberOfPixels).map {
            let angle = startAngle + Double($0) * delta
            return circle.pixel(at: angle)
        }
    }

    /// Calculate the maximum number of pixels for a call to "equidistantPixels:on:numberOfPixels:startAngle:" such that no pixels are returned twice.
    /// This is circa 2pi x r / sqrt(2). The factor of sqrt(2) is required because of diagonal pixels, for example at 45°.
    public static func maxNumberOfPixels(forCircleWithRadius radius: Double) -> Int {
        let minAngle = 2 * tan(sqrt(0.5) / radius)
        return Int(2 * .pi / minAngle)
    }
}
