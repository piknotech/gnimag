//
//  Created by David Knothe on 04.09.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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
        angle = PolarCoordinates.angle(for: position, respectiveTo: center)
        height = position.distance(to: center)
    }

    /// Calculate the cartesian position respective to the center point.
    public func position(respectiveTo center: CGPoint) -> CGPoint {
        return PolarCoordinates.position(atAngle: angle, height: height, respectiveTo: center)
    }

    // MARK: Static

    /// Find the angle for the given point with respect to the center point.
    /// Angle = 0° means right, going counterclockise until 2pi.
    public static func angle(for point: CGPoint, respectiveTo center: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        let atan = atan2(dy, dx)
        return atan < 0 ? atan + 2 * .pi : atan // in [0, 2pi)
    }

    /// Convert the given angle and position back to cartesian coordinates.
    /// Angle = 0° means right, going counterclockise until 2pi.
    public static func position(atAngle angle: CGFloat, height: CGFloat, respectiveTo center: CGPoint) -> CGPoint {
        let x = center.x + cos(angle) * height
        let y = center.y + sin(angle) * height
        return CGPoint(x: x, y: y)
    }
}
