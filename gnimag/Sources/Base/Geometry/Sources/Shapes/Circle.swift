//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// A circle in R^2.
public struct Circle {
    public let center: CGPoint
    public let radius: CGFloat

    /// Default initializer.
    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }

    /// Return the point on the circle at the given angle.
    /// 0 means going right, pi/2 means going up, etc. (counterclockwise).
    public func point(at angle: CGFloat) -> CGPoint {
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        return CGPoint(x: x, y: y)
    }

    /// Return the point on the circle at the given angle.
    /// 0 means going right, pi/2 means going up, etc. (counterclockwise).
    public func point(at angle: Angle) -> CGPoint {
        point(at: CGFloat(angle.value))
    }

    /// Inset the circle by adjusting the radius by the given amount.
    /// Providing a negative amount will make the cicle larger.
    public func inset(by dr: CGFloat) -> Circle {
        Circle(center: center, radius: radius - dr)
    }
}

extension Circle: Shape {
    /// Calculate the unsigned distance to a point.
    public func distance(to point: CGPoint) -> CGFloat {
        abs(center.distance(to: point) - radius)
    }

    /// Check if the point is inside the shape.
    public func contains(_ point: CGPoint) -> Bool {
        point.distance(to: center) <= abs(radius) + 1e-6
    }

    /// The AABB enclosing this shape.
    public var boundingBox: AABB {
        AABB(rect: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
    }
}
