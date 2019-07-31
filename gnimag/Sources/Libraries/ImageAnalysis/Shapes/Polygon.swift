//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An arbitrary polygon underlying no specific restrictions.

public struct Polygon {
    /// The points defining the edges of the polygon. Any two consecutive points define one edge.
    /// Also, the last and the first point in this array define an edge.
    public let points: [CGPoint]

    /// Default initializer.
    public init(points: [CGPoint]) {
        self.points = points
    }
}
