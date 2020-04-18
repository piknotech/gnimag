//
//  Created by David Knothe on 14.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Geometry
import TestingTools

/// Draws a full line at a given height.
struct HorizontalLineScatterStrokable: ScatterStrokable {
    let y: Double

    /// Convert the line into pixel space.
    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let start = frame.pixelPosition(of: (Double(frame.dataContentRect.minX), y))
        let end = frame.pixelPosition(of: (Double(frame.dataContentRect.maxX), y))
        return LineSegment(from: start, to: end)
    }
}
