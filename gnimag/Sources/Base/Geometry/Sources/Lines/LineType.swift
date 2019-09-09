//
//  Created by David Knothe on 08.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//  

import Common
import Foundation

public protocol LineType {
    associatedtype Range: RangeExpression where Range.Bound == CGFloat

    /// The starting point of the line, or any point on the line if the line has no starting point.
    /// When the line has no starting point, that means that `normalizedBounds` are just the real numbers.
    var zeroPoint: CGPoint { get }

    /// True iff the direction is zero, which means that the line is actually just a single point (`zeroPoint`).
    var directionIsZero: Bool { get }

    /// The direction of the line, normalized.
    /// When the `directionIsZero`, the result is unspecified.
    var normalizedDirection: CGPoint { get }

    /// The range of the line, in respect to zeroPoint and normalizedDirection.
    /// This means: for any `t` inside `normalizedBounds`: `zeroPoint + t * normalizedDirection` is on the line.
    var normalizedBounds: Range { get }
}

public extension LineType {
    /// Calculate the unsigned distance to a point.
    func distance(to point: CGPoint) -> CGFloat {
        if directionIsZero { return zeroPoint.distance(to: point) }

        let t = normalizedDirection.dot(point - zeroPoint)
        let clamped = t.clamped(to: normalizedBounds)
        let projection = zeroPoint + clamped * normalizedDirection
        return projection.distance(to: point)
    }
}
