//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry

public enum SmallestAABB {
    /// Calculate the smallest AABB that contains a given (non-empty) set of points.
    /// This runs in O(n) time.
    public static func containing(_ points: [CGPoint]) -> AABB {
        AABB(containing: points)
    }
}
