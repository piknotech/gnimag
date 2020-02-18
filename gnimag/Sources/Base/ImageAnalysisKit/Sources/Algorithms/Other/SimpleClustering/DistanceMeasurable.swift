//
//  Created by David Knothe on 30.07.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
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
}

// MARK: Pixel
extension Pixel: DistanceMeasurable {
    public func distance(to other: Pixel) -> Double {
        sqrt(Double((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)))
    }
}

// MARK: Angle
extension Angle: DistanceMeasurable {
}
