//
//  Created by David Knothe on 30.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

// MARK: DistanceMeasurable
public protocol DistanceMeasurable {
    /// Calculate the distance to another object of the same type.
    /// This distance must always be >= 0.
    func distance(to other: Self) -> Double
}

// MARK: Color
extension Color: DistanceMeasurable {
    public func distance(to other: Color) -> Double {
        euclideanDifference(to: other)
    }
}

// MARK: Pixel
extension Pixel: DistanceMeasurable {
    public func distance(to other: Pixel) -> Double {
        sqrt(Double((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)))
    }
}

// MARK: Angle
/// Angle describes a value in [0, 2pi). Angle defines a useful distance function.
public struct Angle: DistanceMeasurable {
    public let value: Double

    /// Default initializer. Value should be in [0, 2pi).
    public init(value: Double) {
        self.value = value
    }

    /// Calculate the distance to another angle. This distance is always in [0, pi].
    public func distance(to other: Angle) -> Double {
        let dist = abs(value - other.value).truncatingRemainder(dividingBy: 2 * .pi)
        return min(dist, 2 * .pi - dist)
    }
}
