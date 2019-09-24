//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
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
                from: points[i],
                to: points[(i + 1) % points.count]
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
        let aabb = boundingBox
        if !aabb.contains(point) { return false }

        // Special check: is point exactly on the edge?
        if distance(to: point) == 0 { return true }

        // Create random ray and test number of intersections with the polygon
        let angle = CGFloat.random(in: 0 ..< 2 * .pi)
        let direction = CGPoint(x: sin(angle), y: cos(angle))
        let ray = Ray(startPoint: point, direction: direction)
        
        let intersections = lineSegments.count(where: ray.intersects(with:))
        return !intersections.isMultiple(of: 2)
    }

    /// The AABB enclosing this shape.
    public var boundingBox: AABB {
        AABB(containing: points)
    }
}
