//
//  Created by David Knothe on 03.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

/// A PixelPath that creates circles of increasing radii.
/// It happens that some pixels are traversed multiple times (from two adjacent circles), and some pixels are not traversed at all.
public struct ExpandingCirclePath: PixelPath {
    private let center: Pixel
    private let bounds: Bounds
    private let discardRatio: Double
    private let radiusSpeed: Int

    private var currentRadius = 0
    private var currentCirclePath: CirclePath?

    /// Default initializer.
    public init(center: Pixel, bounds: Bounds, discardRatio: Double = 0, radiusSpeed: Int = 1) {
        self.center = center
        self.bounds = bounds
        self.discardRatio = discardRatio
        self.radiusSpeed = radiusSpeed
    }

    /// Return the next pixel on the path.
    public mutating func next() -> Pixel? {
        if let next = currentCirclePath?.next() {
            return next
        } else {
            createNextCirclePath()
            return next()
        }
    }

    /// Increase the radius and create a new circle path.
    private mutating func createNextCirclePath() {
        currentRadius += radiusSpeed
        let circle = Circle(center: center.CGPoint, radius: CGFloat(currentRadius))
        let numPixels = (1 - discardRatio) * 2 * .pi * Double(currentRadius)
        currentCirclePath = CirclePath(circle: circle, numberOfPixels: Int(numPixels), startAngle: 0, bounds: bounds, pixelsOutsideBounds: .skip)
    }
}
