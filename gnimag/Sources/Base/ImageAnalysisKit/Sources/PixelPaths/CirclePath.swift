//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation
import Image
import Geometry

/// A PixelPath that consists of equidistant pixels on a circle. The circle is traversed exactly once.
/// Only pixels inside the given bounds are traversed.
public final class CirclePath: PixelPath {
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
    public let startAngle: CGFloat

    /// The bounds in which the path should be.
    public let bounds: Bounds

    /// If the circle is not fully inside bounds, pixels are either skipped or the path is stopped, depending on pixelsOutsideBoundsMode.
    public let pixelsOutsideBoundsMode: PixelsOutsideBoundsMode

    /// Default initializer.
    public init(circle: Circle, speed: CGFloat = 1, startAngle: CGFloat = 0, bounds: Bounds, pixelsOutsideBounds: PixelsOutsideBoundsMode) {
        self.circle = circle
        self.numberOfPixels = Swift.max(1, Int(round(2 * .pi * circle.radius / speed)))
        self.startAngle = startAngle
        self.bounds = bounds
        self.pixelsOutsideBoundsMode = pixelsOutsideBounds

        delta = 2 * .pi / CGFloat(numberOfPixels)
    }

    // MARK: PixelPath

    /// The number of pixels that already have been traversed.
    private var currentStep = 0

    /// Return the next pixel on the path.
    public override func next() -> Pixel? {
        while currentStep < numberOfPixels {
            if let next = nextOnCircle() {
                return next
            }

            // Point was outside bounds
            switch pixelsOutsideBoundsMode {
            case .skip:
                continue // Try next pixel
            case .stopPath:
                currentStep -= 1 // Undo the increment done by "nextOnCircle"
                return nil
            }
        }

        // While loop exited: "numberOfPixels" has been reached, path has ended
        return nil
    }

    /// Return the next pixel on the circle.
    /// If the bounds are surpassed, return nil.
    private func nextOnCircle() -> Pixel? {
        let angle = startAngle + CGFloat(currentStep) * delta

        let pixel = circle.point(at: angle).nearestPixel
        currentStep += 1

        return bounds.contains(pixel) ? pixel : nil
    }

    private let delta: CGFloat
}

// MARK: Equidistant Pixels
extension CirclePath {
    /// Return "numberOfPixels" equidistant pixels on a circle.
    public static func equidistantPixels(on circle: Circle, numberOfPixels: Int, startAngle: CGFloat = 0) -> [Pixel] {
        let delta = 2 * .pi / CGFloat(numberOfPixels)

        return (0 ..< numberOfPixels).map {
            let angle = startAngle + CGFloat($0) * delta
            return circle.point(at: angle).nearestPixel
        }
    }
}
