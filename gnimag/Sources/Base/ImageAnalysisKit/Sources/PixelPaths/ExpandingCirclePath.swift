//
//  Created by David Knothe on 03.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

/// A PixelPath that creates circles of increasing radii.
/// It happens that some pixels are traversed multiple times (from two adjacent circles), and some pixels are not traversed at all.
public final class ExpandingCirclePath: PixelPath {
    private let center: Pixel
    private let bounds: Bounds
    private let onCircleSpeed: CGFloat
    private let radiusSpeed: CGFloat

    private var currentRadius: CGFloat = 0
    private var currentCirclePath: CirclePath?

    private var isFirstNextCallOnNewCircle = false

    /// Default initializer.
    public init(center: Pixel, bounds: Bounds, onCircleSpeed: CGFloat = 1, radiusSpeed: CGFloat = 1) {
        self.center = center
        self.bounds = bounds
        self.onCircleSpeed = onCircleSpeed
        self.radiusSpeed = radiusSpeed
    }

    /// Return the next pixel on the path.
    public override func next() -> Pixel? {
        if let next = currentCirclePath?.next() {
            isFirstNextCallOnNewCircle = false
            return next
        } else {
            if isFirstNextCallOnNewCircle { return nil } // Circle radius large than bounds allow
            createNextCirclePath()
            return next()
        }
    }

    /// Increase the radius and create a new circle path.
    private func createNextCirclePath() {
        currentRadius += radiusSpeed
        let circle = Circle(center: center.CGPoint, radius: currentRadius)
        currentCirclePath = CirclePath(circle: circle, speed: onCircleSpeed, bounds: bounds, pixelsOutsideBounds: .skip)
        isFirstNextCallOnNewCircle = true
    }
}
