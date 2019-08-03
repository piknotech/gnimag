//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public enum SmallestOBB {
    /// Properties of an OBB that can be minimized when calculating the smallest (respective to this property) OBB.
    public enum MinimizingProperty {
        case area
        case perimeter
        case diameter
    }

    /// Calculate the smallest OBB that contains a given (non-empty) set of points.
    /// This runs in O(n log n + nh) time where h is the number of points on the convex hull.
    public static func containing(_ points: [CGPoint], minimizing minimizingProperty: MinimizingProperty) -> OBB {
        // Calculate and use the convex hull as the smallest OBB of the set of points is the same as the smallest OBB of their convex hull
        let hull = ConvexHull.from(points)

        var bestValue = CGFloat.infinity
        var bestOBB: OBB?

        // Iterate through each line segment and construct an OBB containing this line segment
        for i in 0 ..< hull.points.count {
            // Get line segment (start, end), having direction "dir"
            let start = hull.points[i]
            let end = hull.points[(i + 1) % hull.points.count]
            let dir = end - start
            if dir == .zero { continue } // Safety check

            // Calculate directed angle between dir and x-axis
            // Angle is in [-pi/2, pi/2]
            var angle = acos(dir.x / dir.length)
            if angle > .pi / 2 { angle = .pi - angle }
            if dir.x * dir.y < 0 { angle = -angle }

            // Rotate all points by the angle (counterclockwise); this will rotate the coordinate system so that (start, end) is parallel to the x-axis
            let rotated = points.map { $0.rotated(by: angle) }

            // Get AABB from the rotated points
            let aabb = SmallestAABB.containing(rotated)

            // Rotate center point back
            let center = CGPoint(x: aabb.rect.midX, y: aabb.rect.midY)
            let rotatedCenter = center.rotated(by: -angle)

            // Compare OBB with previous ones
            let obb = OBB(center: rotatedCenter, width: aabb.width, height: aabb.height, rotation: angle)
            let rating = value(of: minimizingProperty, of: obb)
            if rating < bestValue {
                bestValue = rating
                bestOBB = obb
            }
        }

        return bestOBB!
    }

    /// Calculate the value of the specified property of an OBB.
    private static func value(of property: MinimizingProperty, of obb: OBB) -> CGFloat {
        switch property {
        case .area:
            return obb.width * obb.height
        case .perimeter:
            return 2 * (obb.width + obb.height)
        case .diameter:
            return sqrt(obb.width * obb.width + obb.height * obb.height)
        }
    }
}
