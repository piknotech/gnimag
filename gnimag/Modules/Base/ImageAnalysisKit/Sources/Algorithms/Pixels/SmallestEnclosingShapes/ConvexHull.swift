//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//
// Taken from https://en.m.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain

import Foundation
import Geometry
import Image

public enum ConvexHull {
    /// Calculate the convex hull of a given set of pixels using Andrew's monotone chain convex hull algorithm.
    /// The resulting polygon consists of the hull points, stored in a counterclockwise order.
    /// This runs in O(n log n) time.
    public static func from(_ pixels: [Pixel]) -> Geometry.Polygon {
        from(pixels.map(CGPoint.init))
    }

    /// Calculate the convex hull of a given set of points using Andrew's monotone chain convex hull algorithm.
    /// The resulting polygon consists of the hull points, stored in a counterclockwise order.
    /// This runs in O(n log n) time.
    public static func from(_ points: [CGPoint]) -> Geometry.Polygon {
        guard points.count > 2 else { return Polygon(points: points) }

        var lower = [CGPoint]()
        var upper = [CGPoint]()

        // Sort points by x-coordinate
        let points = points.sorted { a, b in
            a.x < b.x || a.x == b.x && a.y < b.y
        }

        // Construct the lower hull
        for point in points {
            while lower.count >= 2 {
                let a = lower[lower.count - 2]
                let b = lower[lower.count - 1]
                if (b - a).cross(point - a) > 0 { break }
                lower.removeLast()
            }
            lower.append(point)
        }

        // Construct the upper hull
        for point in points.lazy.reversed() {
            while upper.count >= 2 {
                let a = upper[upper.count - 2]
                let b = upper[upper.count - 1]
                if (b - a).cross(point - a) > 0 { break }
                upper.removeLast()
            }
            upper.append(point)
        }

        // Remove each array’s last point, as it’s the same as the first point in the opposite array, respectively
        lower.removeLast()
        upper.removeLast()

        // Join the arrays to form the convex hull
        return Polygon(points: lower + upper)
    }
}
