//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Input

/// A PixelPath that consists of a straight line. The path stops when the given bounds have been reached.

public struct StraightPath: PixelPath {
    /// The start pixel. It must be inside the bounds, else the walk is empty.
    public let start: Pixel

    /// The angle, 0 meaning going right, pi/2 meaning going up, etc. (counterclockwise).
    public let angle: Double

    /// The speed of the walk (>= 1). 1 means that, each step, the nearest pixel is chosen, whereas higher values mean that more distant pixels are chosen.
    /// This value has a linear effect on the number of pixels in the path.
    public let speed: Double

    /// The bounds in which the walk should be performed.
    public let bounds: Bounds

    /// Default initializer.
    public init(start: Pixel, angle: Double, bounds: Bounds, speed: Double = 1) {
        self.start = start
        self.angle = angle
        self.bounds = bounds
        self.steps = 0

        // If the walk is i.e. diagonal, speed must be multiplied with 1.41 to avoid returning pixels twice.
        // Therefore, each step is exactly so long that either in x- or in y-direction, exactly one new pixel is hit each time.
        let mod = abs(angle).truncatingRemainder(dividingBy: .pi) // 0 <= mod < 180°
        let slope = (mod < .pi / 4 || mod > .pi * 3/4) ? tan(angle) : tan(angle - .pi / 2)
        let multiplicator = sqrt(1 + slope * slope)
        self.speed = Double(speed) * multiplicator
    }

    /// Convenience initializer. Instead of the angle, here you pass another point where the ray should pass through.
    public init(start: Pixel, through: Pixel, bounds: Bounds, speed: Double = 1) {
        let dy = Double(through.y - start.y)
        let dx = Double(through.x - start.x)
        let angle = atan2(dy, dx)
        self.init(start: start, angle: angle, bounds: bounds, speed: speed)
    }

    // MARK: PixelPath

    /// The number of steps that have been taken already.
    private var steps: Int

    /// Return the next pixels on the path.
    public mutating func next(_ num: Int) -> [Pixel] {
        var result = [Pixel]()

        // Get next pixel "num" times
        for _ in 0 ..< num {
            guard let next = next() else { break }
            result.append(next)
        }

        return result
    }

    /// Return the single next pixel on the path.
    /// If the bounds are surpassed, return nil
    private mutating func next() -> Pixel? {
        let x = Double(start.x) + cos(angle) * speed * Double(steps)
        let y = Double(start.y) - sin(angle) * speed * Double(steps)
        let pixel = Pixel(Int(round(x)), Int(round(y)))

        // Boundary check
        guard bounds.contains(pixel) else { return nil }

        steps += 1
        return pixel
    }
}
