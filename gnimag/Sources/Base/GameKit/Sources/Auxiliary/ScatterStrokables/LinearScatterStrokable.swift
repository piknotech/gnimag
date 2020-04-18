//
//  Created by David Knothe on 26.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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
    public func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let bounds = drawingRange.intersection(with: frame.dataContentXRange)
        if bounds.isEmpty { return EmptyStrokable() }
        
        let x1 = bounds.lower
        let x2 = bounds.upper
        let y1 = line.at(x1), y2 = line.at(x2)

        // Convert into scatter plot space
        let point1 = frame.pixelPosition(of: (x1, y1))
        let point2 = frame.pixelPosition(of: (x2, y2))

        return LineSegment(from: point1, to: point2)
    }
}

/// A Strokable which does nothing.
internal struct EmptyStrokable: Strokable {
    func stroke(onto context: CGContext) {
    }
}
