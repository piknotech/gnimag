//
//  Created by David Knothe on 03.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Angle describes a value in [0, 2pi). Angle defines a useful distance function.
public struct Angle {
    /// The value, which is always in [0, 2pi).
    public let value: Double

    /// Default initializer, using a Double value.
    public init(_ value: Double) {
        self.value = value.truncatingRemainder(dividingBy: 2 * .pi)
    }

    /// Default initializer, using a CGFloat value. Value should be in [0, 2pi).
    public init(_ value: CGFloat) {
        self.value = Double(value)
    }

    /// Calculate the distance to another angle. This distance is always in [0, pi].
    public func distance(to other: Angle) -> Double {
        let dist = abs(value - other.value).truncatingRemainder(dividingBy: 2 * .pi)
        return min(dist, 2 * .pi - dist)
    }

    /// Calculate the midpoint between this angle and the other angle.
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
