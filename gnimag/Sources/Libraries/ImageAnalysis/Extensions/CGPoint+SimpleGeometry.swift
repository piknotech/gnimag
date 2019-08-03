//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public extension CGPoint {
    /// Return the distance to the given point.
    func distance(to other: CGPoint) -> CGFloat {
        (self - other).length
    }

    /// Return the z component of the cross product with another point.
    func cross(_ other: CGPoint) -> CGFloat {
        x * other.y - y * other.x
    }

    /// The dot product of self and other, where self and other are interpreted as vectors.
    func dot(_ other: CGPoint) -> CGFloat {
        return x * other.x + y * other.y
    }

    /// Rotate this point by an angle, counterclockwise, around the origin.
    func rotated(by angle: CGFloat, around center: CGPoint = .zero) -> CGPoint {
        let diff = self - center
        let rotX = diff.x * cos(angle) - diff.y * sin(angle)
        let rotY = diff.x * sin(angle) + diff.y * cos(angle)
        return CGPoint(x: center.x + rotX, y: center.y + rotY)
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
