//
//  Created by David Knothe on 04.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// PolarCoordinates provides simple conversion between cartesian and polar coordinates.
public struct PolarCoordinates {
    public let angle: CGFloat
    public let height: CGFloat

    /// Default initializer.
    public init(angle: CGFloat, height: CGFloat) {
        self.angle = angle
        self.height = height
    }

    /// Create PolarCoordinates from the given position with respect to the center point.
    /// Height >= 0; angle = 0° means right, going counterclockise until 2pi.
    public init(position: CGPoint, center: CGPoint) {
        let dx = position.x - center.x
        let dy = position.y - center.y

        // Calculate angle and height
        let atan = atan2(dy, dx)
        angle = atan < 0 ? atan + 2 * .pi : atan // in [0, 2pi)
        height = sqrt(dx * dx + dy * dy)
    }

    /// Calculate the cartesian position respective to the center point.
    public func position(respectiveTo center: CGPoint) -> CGPoint {
        let x = center.x + cos(angle) * height
        let y = center.y + sin(angle) * height
        return CGPoint(x: x, y: y)
    }
}

fileprivate extension CGPoint {
    /// Return the distance to the given point.
    func distance(to point: CGPoint) -> Double {
        let dx = x - point.x
        let dy = y - point.y
        return Double(sqrt(dx * dx + dy * dy))
    }
}
