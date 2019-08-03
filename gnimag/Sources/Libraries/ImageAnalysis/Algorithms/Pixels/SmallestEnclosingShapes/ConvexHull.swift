//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//
// Taken from https://en.m.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain

import Foundation

public enum ConvexHull {
    /// Calculate the convex hull of a given set of points using Andrew's monotone chain convex hull algorithm.
    /// This runs in O(n log n) time.
    public static func from(_ points: [CGPoint]) -> Polygon {
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
                if (b - a).cross(point - a) > 0 { break } // TODO: check ob point am ende counterclockwise sind (weil coordinate system unten links beginnt!)
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
