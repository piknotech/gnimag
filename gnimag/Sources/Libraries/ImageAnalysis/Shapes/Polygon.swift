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
}
