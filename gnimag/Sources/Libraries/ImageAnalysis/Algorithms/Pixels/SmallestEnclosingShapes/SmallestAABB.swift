//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public enum SmallestAABB {
    /// Calculate the smallest AABB that contains a given (non-empty) set of points.
    /// This runs in O(n) time.
    public static func containing(_ points: [CGPoint]) -> AABB {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }

        let minX = xs.min()!
        let minY = ys.min()!
        let maxX = xs.max()!
        let maxY = ys.max()!

        let origin = CGPoint(x: minX, y: minY)
        let size = CGSize(width: maxX - minX, height: maxY - minY)
        return AABB(rect: CGRect(origin: origin, size: size))
    }
}
