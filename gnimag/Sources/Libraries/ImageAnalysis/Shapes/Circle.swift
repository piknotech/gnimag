//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// A circle in R^2.

public struct Circle {
    public let center: CGPoint
    public let radius: Double

    /// Return the point on the circle at the given angle.
    /// 0 means going right, pi/2 means going up, etc. (counterclockwise).
    public func point(at angle: Double) -> CGPoint {
        let x = Double(center.x) + cos(angle) * radius
        let y = Double(center.y) - sin(angle) * radius
        return CGPoint(x: x, y: y)
    }
}
