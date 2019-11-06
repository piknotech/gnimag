//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

/// A PixelPath that consists of a straight line. The path stops when the given bounds have been reached.
public final class StraightPath: PixelPath {
    /// The start pixel. It must be inside the bounds, else the path is empty.
    public let start: Pixel

    /// The angle, 0 meaning going right, pi/2 meaning going up, etc. (counterclockwise).
    public let angle: CGFloat

    /// The speed of the ray (>= 1). 1 means that, each step, the nearest pixel is chosen, whereas higher values mean that more distant pixels are chosen.
    /// This value has a linear effect on the number of pixels in the path.
    public let speed: CGFloat

    /// The bounds in which the path should be.
    public let bounds: Bounds

    /// For performance reasons, instead of calculating sin/cos each time, the next pixel is calculated incrementally from the last one.
    private var current: CGPoint
    private let sinAngle: CGFloat
    private let cosAngle: CGFloat

    /// Default initializer.
    public init(start: Pixel, angle: CGFloat, bounds: Bounds, speed: CGFloat = 1) {
        self.start = start
        self.angle = angle
        self.bounds = bounds

        current = start.CGPoint
        sinAngle = sin(angle)
        cosAngle = cos(angle)

        // If the ray is i.e. diagonal, speed must be multiplied with 1.41 to avoid returning pixels twice.
        // Therefore, each step is exactly so long that either in x- or in y-direction, exactly one new pixel is hit each time.
        let mod = abs(angle).truncatingRemainder(dividingBy: .pi) // 0 <= mod < 180°
        let slope = (mod < .pi / 4 || mod > .pi * 3/4) ? tan(angle) : tan(angle - .pi / 2)
        let multiplicator = sqrt(1 + slope * slope)
        self.speed = speed * multiplicator
    }

    /// Convenience initializer. Instead of the angle, here you pass another point where the ray should pass through.
    public convenience init(start: Pixel, through: Pixel, bounds: Bounds, speed: CGFloat = 1) {
        let dy = CGFloat(through.y - start.y)
        let dx = CGFloat(through.x - start.x)
        let angle = atan2(dy, dx)
        self.init(start: start, angle: angle, bounds: bounds, speed: speed)
    }

    // MARK: PixelPath

    /// Return the next pixel on the path.
    /// If the bounds are surpassed, return nil.
    public override func next() -> Pixel? {
        let pixel = current.nearestPixel
        guard bounds.contains(pixel) else { return nil }

        current.x += speed * cosAngle
        current.y += speed * sinAngle

        return pixel
    }
}
