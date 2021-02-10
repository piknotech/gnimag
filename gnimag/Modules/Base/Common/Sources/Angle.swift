//
//  Created by David Knothe on 03.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// Angle describes a value in [0, 2pi). Angle defines a useful distance function.
public struct Angle: Equatable {
    /// The value, which is always in [0, 2pi).
    public let value: Double

    /// Default initializer, using a Double value. A modulo-2-pi is applied to the value.
    public init(_ value: Double) {
        var modulo = value.truncatingRemainder(dividingBy: 2 * .pi)

        // The result of `truncatingRemainder` is negative for negative values; in this case, add 2pi
        if modulo < 0 { modulo += 2 * .pi }
        self.value = modulo
    }

    /// Default initializer, using a CGFloat value. A modulo-2-pi is applied to the value.
    public init(_ value: CGFloat) {
        self.init(Double(value))
    }

    /// The zero angle.
    public static let zero = Angle(0.0)

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value
    }

    /// Calculate the distance to another angle. This distance is always in [0, pi].
    public func distance(to other: Angle) -> Double {
        let dist = abs(value - other.value).truncatingRemainder(dividingBy: 2 * .pi)
        return min(dist, 2 * .pi - dist)
    }

    /// Calculate the directed distance to another angle. This means, the radial distance that has to be passed in a given `direction` (positive or negative) to get from `self` to `other`.
    /// Only the sign of `direction` is relevant; direction must not be 0.
    /// The result is always in [0, 2pi).
    public func directedDistance(to other: Angle, direction: Double) -> Double {
        if direction == 0 { return 0 }
        let sign: Double = (direction > 0) ? 1 : -1

        var dist = (other.value - value) * sign
        if dist < 0 { dist += 2 * .pi }

        return dist
    }

    /// Calculate the midpoint between `self` and `other`.
    public func midpoint(between other: Angle) -> Angle {
        let mid = (value + other.value) / 2

        // If it is nearer to go around the circle by crossing the 0/2pi-border, the midpoint is on the other side of the circle – add .pi
        if abs(value - other.value) < .pi {
            return Angle(mid)
        } else {
            return Angle(mid + .pi)
        }
    }

    /// Determine whether `self` is in the *open* interval (`angle1`, `angle2`) using the given direction.
    /// This means: when going upwards (or downwards) from `angle1`, `self` must come before `angle2`.
    /// If the bounds coincide or one of the bounds coincides with `self`, return false.
    /// Switching the places of `angle1` and `angle2` or negating `direction` switches the result of this call (except when direction = 0, angle1 = angle2, self = angle1 or self = angle2).
    public func isBetween(_ angle1: Angle, and angle2: Angle, direction: Double) -> Bool {
        if direction == 0 || angle1 == angle2 || self == angle1 || self == angle2 { return false }
        return directedDistance(to: angle2, direction: direction) < directedDistance(to: angle1, direction: direction)
    }
}
