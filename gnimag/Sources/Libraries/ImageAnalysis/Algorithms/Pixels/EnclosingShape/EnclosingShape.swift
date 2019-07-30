//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// EnclosingShape bundles all enclosing shape algorithms.

public enum EnclosingShape {
    /// Calculate the smallest circle that contains a given (non-empty) set of points.
    /// This requires linear time.
    public static func circle(from points: [CGPoint]) -> Circle {
        SmallestCircle.containing(points)
    }
}
