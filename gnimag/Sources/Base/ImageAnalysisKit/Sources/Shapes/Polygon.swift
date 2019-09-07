//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An arbitrary polygon underlying no specific restrictions.
/// The points of the polygon are stored in a counterclockwise manner.
public struct Polygon {
    /// The points defining the edges of the polygon. Any two consecutive points define one edge.
    /// Also, the last and the first point in this array define an edge.
    /// The points are stored in a counterclockwise manner.
    public let points: [CGPoint]

    /// The line segments the polygon consists of.
    public var lineSegments: [LineSegment] {
        (0 ..< points.count).map { i in
            LineSegment(
                p1: points[i],
                p2: points[(i + 1) % points.count]
            )
        }
    }

    /// Default initializer. The points must be in counterclockwise order.
    public init(points: [CGPoint]) {
        self.points = points
    }
}

extension Polygon: Shape {
    /// Calculate the unsigned distance to a point.
    /// Precondition: The polygon consists of at least one point.
    public func distance(to point: CGPoint) -> CGFloat {
        lineSegments.map { $0.distance(to: point) }.min()!
    }

    /// Check if the point is inside the shape.
    public func contains(_ point: CGPoint) -> Bool {
        // First, check if point is in the bounding box
        let aabb = self.aabb
        if !aabb.contains(point) { return false }

        // Create random ray and test number of intersections with the polygon
        let angle = CGFloat.random(in: 0 ..< 2 * .pi)
        let scale = aabb.width + aabb.height // Can be replaced once "Ray" is introduced as a Shape/LineType
        let p2 = CGPoint(x: point.x + sin(angle) * scale, y: cos(angle) * scale)
        let ray = LineSegment(p1: point, p2: p2)

        let intersections = lineSegments.count(where: ray.intersects(with:))
        return !intersections.isMultiple(of: 2)
    }

    private var aabb: AABB {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let xMin = xs.min()!, yMin = ys.min()!
        let xMax = xs.max()!, yMax = ys.max()!
        return AABB(rect: CGRect(x: xMin, y: yMin, width: xMax - xMin, height: yMax - yMin))
    }
}
