//
//  Created by David Knothe on 20.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Geometry
import TestingTools

/// Draws a full line at a given height in data-point-space.
public struct HorizontalLineScatterStrokable: ScatterStrokable {
    let y: Double

    /// Default initializer.
    public init(y: Double) {
        self.y = y
    }

    /// Convert the line into pixel space.
    public func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let start = frame.pixelPosition(of: (Double(frame.dataContentRect.minX), y))
        let end = frame.pixelPosition(of: (Double(frame.dataContentRect.maxX), y))
        return LineSegment(from: start, to: end)
    }
}

/// Draws a full line at a given width in data-point-space.
public struct VerticalLineScatterStrokable: ScatterStrokable {
    let x: Double

    /// Default initializer.
    public init(x: Double) {
        self.x = x
    }

    /// Convert the line into pixel space.
    public func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let start = frame.pixelPosition(of: (x, (Double(frame.dataContentRect.minY))))
        let end = frame.pixelPosition(of: (x, (Double(frame.dataContentRect.maxY))))
        return LineSegment(from: start, to: end)
    }
}
