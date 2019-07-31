//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public extension CGPoint {
    /// Return the distance to the given point.
    func distance(to other: CGPoint) -> Double {
        Double((self - other).length)
    }

    /// Return the z component of the cross product with another point.
    func cross(_ other: CGPoint) -> Double {
        Double(x * other.y - y * other.x)
    }

    /// The dot product of self and other, where self and other are interpreted as vectors.
    func dot(_ other: CGPoint) -> CGFloat {
        return x * other.x + y * other.y
    }

    /// Rotate this point by an angle, counterclockwise, around the origin.
    func rotated(by angle: CGFloat) -> CGPoint {
        CGPoint(
            x: x * cos(angle) - y * sin(angle),
            y: x * sin(angle) + y * cos(angle)
        )
    }

    /// Return the length of the point interpreted as vector.
    var length: CGFloat {
        sqrt(x * x + y * y)
    }

    /// Return the difference between two points.
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

