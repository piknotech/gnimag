//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// A line segment connecting two points.
public struct LineSegment {
    public let p1: CGPoint
    public let p2: CGPoint

    /// Default initializer.
    public init(p1: CGPoint, p2: CGPoint) {
        self.p1 = p1
        self.p2 = p2
    }
}

extension LineSegment: Shape {
    /// Calculate the unsigned distance to a point.
    public func distance(to point: CGPoint) -> CGFloat {
        if p1 == p2 { return p1.distance(to: point) }

        let distSquared = pow(p1.distance(to: p2), 2)
        let t = (point - p1).dot(p2 - p1) / distSquared
        let c = max(0, min(1, t)) // Important for line segments
        let projection = CGPoint(x: p1.x + c * (p2 - p1).x, y: p1.y + c * (p2 - p1).y)
        return point.distance(to: projection)
    }

    public func contains(_ point: CGPoint) -> Bool {
        return false
    }
}

extension LineSegment {
    private var boundingRect: CGRect {
        CGRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p1.x - p2.x), height: abs(p1.y - p2.y))
    }

    /// Checks if two line segments intersect.
    /// If the line segments are collinear, return true iff the have points in common.
    /// Taken from https://github.com/pgkelley4/line-segments-intersect/blob/master/js/line-segments-intersect.js
    public func intersects(with other: LineSegment) -> Bool {
        let dir1 = p2 - p1
        let dir2 = other.p2 - other.p1

        let num = (other.p1 - p1).cross(dir1)
        let denom = dir1.cross(dir2)

        if num == 0 && denom == 0 {
            // Collinear, check if points are contained in the other line
            return other.boundingRect.contains(p1) || other.boundingRect.contains(p2)
        }

        if denom == 0 {
            // Parallel, but not collinear
            return false
        }

        // Check if u/denom and t/denom are in [0,1].
        // This implementation, in contrast to the one linked, does not perform division by denom.
        let sign: CGFloat = (denom > 0) ? 1 : -1
        let u = num * sign
        let t = (other.p1 - p1).cross(dir2) * sign
        return (0...denom).contains(u) && (0...denom).contains(t)
    }
}
