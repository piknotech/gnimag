//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An oriented bounding box.
public struct OBB {
    /// The AABB, which must be rotated around its center to retrieve the actual OBB.
    public let aabb: AABB

    /// The rotation, counterclockwise, in [-pi/2, pi/2].
    public let rotation: CGFloat

    /// Default initializer.
    public init(aabb: AABB, rotation: CGFloat) {
        self.aabb = aabb
        self.rotation = rotation
    }

    /// Convenience initializer.
    public init(center: CGPoint, width: CGFloat, height: CGFloat, rotation: CGFloat) {
        aabb = AABB(center: center, width: width, height: height)
        self.rotation = rotation
    }

    public var center: CGPoint { aabb.center }
    public var width: CGFloat { aabb.width }
    public var height: CGFloat { aabb.height }
}

extension OBB: Shape {
    /// Calculate the unsigned distance to a point.
    public func distance(to point: CGPoint) -> CGFloat {
        let point = point.rotated(by: -rotation, around: center)
        return aabb.distance(to: point)
    }

    /// Check if the point is inside the shape.
    public func contains(_ point: CGPoint) -> Bool {
        let point = point.rotated(by: -rotation, around: center)
        return aabb.contains(point)
    }
}
