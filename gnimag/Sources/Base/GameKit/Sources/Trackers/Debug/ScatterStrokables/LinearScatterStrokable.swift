//
//  Created by David Knothe on 26.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import TestingTools

/// LinaerScatterStrokable is a ScatterStrokable that can draw a line (segment).
public struct LinearScatterStrokable: ScatterStrokable {
    /// The line in the data point space.
    let line: LinearFunction

    /// The x value range where the line should be drawn (in data point space).
    /// Attention: the range must be regular, i.e. upper > lower.
    let drawingRange: SimpleRange<Double>

    /// Default initializer.
    public init(line: LinearFunction, drawingRange: SimpleRange<Double>) {
        self.line = line
        self.drawingRange = drawingRange
    }

     /// Return the concrete strokable for drawing onto a specific ScatterPlot.
    public func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        let x1 = max(drawingRange.lower, Double(scatterPlot.dataContentRect.minX))
        let x2 = min(drawingRange.upper, Double(scatterPlot.dataContentRect.maxX))
        let y1 = line.at(x1), y2 = line.at(x2)

        // Convert into scatter plot space
        let point1 = scatterPlot.pixelPosition(of: (x1, y1))
        let point2 = scatterPlot.pixelPosition(of: (x2, y2))

        return LineSegment(from: point1, to: point2)
    }
}
