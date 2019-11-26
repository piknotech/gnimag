//
//  Created by David Knothe on 26.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Geometry
import MacTestingTools

/// QuadCurveScatterStrokable is a ScatterStrokable that can draw a parabola curve using a bezier path.
public struct QuadCurveScatterStrokable: ScatterStrokable {
    public let color: ScatterColor

    /// The parabola in the data point space.
    let parabola: Polynomial

    /// The x value range where the parabola should be drawn (in data point space).
    /// Attention: the range must be regular, i.e. upper > lower.
    let drawingRange: SimpleRange<Double>

     /// Return the concrete strokable for drawing onto a specific ScatterPlot.
    public func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        guard parabola.degree == 2 else {
            exit(withMessage: "QuadCurveScatterStrokable can only draw polynomials of degree 2!")
        }

        // Attention: left is always the lowest value, even if the ranges are inverted
        let x1 = max(drawingRange.lower, Double(scatterPlot.contentRect.minX))
        let x3 = max(drawingRange.upper, Double(scatterPlot.contentRect.maxX))
        let y1 = parabola.at(x1), y3 = parabola.at(x3)

        // Find intersection point of the tangents at (x1, y1) and (x3, y3)
        let deriv1 = parabola.derivative.at(x1)
        let deriv3 = parabola.derivative.at(x3)
        let ray1 = Ray(startPoint: CGPoint(x: x1, y: y1), direction: CGPoint(x: 1, y: deriv1))
        let ray3 = Ray(startPoint: CGPoint(x: x3, y: y3), direction: CGPoint(x: 1, y: deriv3))
        let intersection = ray1.intersection(with: ray3)!
        let x2 = Double(intersection.x), y2 = Double(intersection.y)

        // Convert into scatter plot space
        let point1 = scatterPlot.pixelPosition(of: (x1, y1))
        let point2 = scatterPlot.pixelPosition(of: (x2, y2))
        let point3 = scatterPlot.pixelPosition(of: (x3, y3))

        return QuadCurveStrokable(point1: point1, point2: point2, point3: point3)
    }
}

fileprivate struct QuadCurveStrokable: Strokable {
    let point1: CGPoint
    let point2: CGPoint
    let point3: CGPoint

    /// Stroke the quadratic curve defined by the three control points `point1`, `point2` and `point3`.
    func stroke(onto context: CGContext) {
        context.beginPath()
        context.move(to: point1)
        context.addQuadCurve(to: point3, control: point2)
        context.strokePath()
    }
}
