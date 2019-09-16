//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// A Shape allows measuring the distance from its border to a point.
public protocol Shape {
    /// Calculate the unsigned distance to from the border of this shape to a point.
    /// 0 means the point is on the border, >0 means the point is either inside or outside the shape.
    /// The distance cannot be negative.
    func distance(to point: CGPoint) -> CGFloat

    /// Check if the point is inside the shape or on the border.
    func contains(_ point: CGPoint) -> Bool
}
