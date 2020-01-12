//
//  Created by David Knothe on 03.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Angle describes a value in [0, 2pi). Angle defines a useful distance function.
public struct Angle {
    /// The value, which is always in [0, 2pi).
    public let value: Double

    /// Default initializer, using a Double value. A modulo-2-pi is applied to the value.
    public init(_ value: Double) {
        self.value = value.truncatingRemainder(dividingBy: 2 * .pi)
    }

    /// Default initializer, using a CGFloat value. A modulo-2-pi is applied to the value.
    public init(_ value: CGFloat) {
        self.init(Double(value))
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
}
