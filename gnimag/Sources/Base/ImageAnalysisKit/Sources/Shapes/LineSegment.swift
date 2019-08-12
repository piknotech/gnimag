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
}
