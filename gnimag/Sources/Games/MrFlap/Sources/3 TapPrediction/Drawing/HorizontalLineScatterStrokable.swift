//
//  Created by David Knothe on 14.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import TestingTools

/// Draws a full line at a given height.
struct HorizontalLineScatterStrokable: ScatterStrokable {
    let y: Double

    /// Convert the line into pixel space.
    func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        let start = scatterPlot.pixelPosition(of: (Double(scatterPlot.dataContentRect.minX), y))
        let end = scatterPlot.pixelPosition(of: (Double(scatterPlot.dataContentRect.maxX), y))
        return LineSegment(from: start, to: end)
    }
}
