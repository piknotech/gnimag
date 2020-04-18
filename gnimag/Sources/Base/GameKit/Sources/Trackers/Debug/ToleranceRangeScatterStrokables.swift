//
//  Created by David Knothe on 17.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import TestingTools

internal struct VerticalLineSegmentScatterStrokable: ScatterStrokable {
    let x: Double
    let yCenter: Double
    let yRadius: Double

    /// Convert the line into pixel space.
    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let start = frame.pixelPosition(of: (x, yCenter - yRadius))
        let end = frame.pixelPosition(of: (x, yCenter + yRadius))
        return LineSegment(from: start, to: end)
    }
}

internal struct EllipseScatterStrokable: ScatterStrokable {
    let center: (x: Double, y: Double)
    let radii: (x: Double, y: Double)

    /// Convert the ellipse into pixel space.
    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let xFactor = frame.pixelContentRect.width / frame.dataContentRect.width
        let yFactor = frame.pixelContentRect.height / frame.dataContentRect.height

        let center = frame.pixelPosition(of: self.center)
        let rx = CGFloat(radii.x) * xFactor
        let ry = CGFloat(radii.y) * yFactor

        return EllipseStrokable(
            rect: CGRect(x: center.x - rx, y: center.y - ry, width: 2 * rx, height: 2 * ry)
        )
    }
}

fileprivate struct EllipseStrokable: Strokable {
    let rect: CGRect

    func stroke(onto context: CGContext) {
        context.strokeEllipse(in: rect)
    }
}
