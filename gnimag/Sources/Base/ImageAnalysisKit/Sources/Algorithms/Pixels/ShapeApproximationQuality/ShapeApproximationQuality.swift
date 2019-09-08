//
//  Created by David Knothe on 02.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry

extension Array where Element == CGPoint {
    /// Quality requirements that allow deciding if a shape approximates a point set good enough or not.
    public struct ShapeQualityRequirements {
        /// The maximum distance where a point is still counted as "good".
        public let maxToleratedDistance: CGFloat

        /// The relative amount of points that must be "good" in order for the shape to pass the test.
        /// Must be between 0 and 1.
        public let requiredAmountOfGoodPoints: Double

        /// Default initializer.
        public init(maxToleratedDistance: CGFloat, requiredAmountOfGoodPoints: Double) {
            self.maxToleratedDistance = maxToleratedDistance
            self.requiredAmountOfGoodPoints = requiredAmountOfGoodPoints
        }
    }

    /// Return true iff the given shape is a good enough approximation for this point array.
    /// The decision is done as follows:
    /// • For each point, calculate the distance to the shape
    /// • Count the number of points where distance > maxToleratedDistance
    /// • Iff this count is too high (>= 1 - requiredAmountOfGoodPoints), the shape does not meet the quality requirements.
    public func shapeApproximation(_ shape: Shape, meets qualityRequirements: ShapeQualityRequirements) -> Bool {
        let number = count { shape.distance(to: $0) <= qualityRequirements.maxToleratedDistance }
        return Double(number) >= Double(count) * qualityRequirements.requiredAmountOfGoodPoints
    }
}
