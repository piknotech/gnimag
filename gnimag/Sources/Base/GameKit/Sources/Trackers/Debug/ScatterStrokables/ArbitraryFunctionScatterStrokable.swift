//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Geometry
import MacTestingTools

/// A ScatterStrokable that can draw any function by calculating and connecting points on the function at certain intervals.
public struct ArbitraryFunctionScatterStrokable: ScatterStrokable {
    /// The function in the data point space.
    let function: Function

    /// The x value range where the function should be drawn (in data point space).
    /// Attention: the range must be regular, i.e. upper > lower.
    let drawingRange: SimpleRange<Double>

    /// The minimum number of interpolation points that will be used.
    /// If the function is curvy (high derivative), more points will be used, up to `2 * interpolationPoints`.
    let interpolationPoints: Int

     /// Return the concrete strokable for drawing onto a specific ScatterPlot.
    public func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        // Attention: left is always the lowest value, even if the ranges are inverted
        let start = max(drawingRange.lower, Double(scatterPlot.dataContentRect.minX))
        let end = min(drawingRange.upper, Double(scatterPlot.dataContentRect.maxX))

        let accuracy = CGFloat(end - start) / CGFloat(interpolationPoints)

        // Use the derivative for better point distribution if the function is differentiable
        let derivative = (function as? DifferentiableFunction)?.derivative

        var result = [CGPoint]()
        var x = start

        // Function traversal
        while x <= end {
            // Convert to pixel space
            let point = scatterPlot.pixelPosition(of: (x, function.at(x)))
            result.append(point)

            // Calculate x-delta to the next point (between acc/2 and acc, depending on the slope)
            // First, calculate the derivative in pixel space
            let deriv = abs(CGFloat(derivative?.at(x) ?? 0))
            let yStretch = scatterPlot.pixelContentRect.height / scatterPlot.dataContentRect.height
            let xStretch = scatterPlot.pixelContentRect.width / scatterPlot.dataContentRect.width
            let scaledDeriv = deriv * yStretch / xStretch

            // d is the x-delta to exactly go `accuracy` pixels on the graph.
            // We transform d from [0, acc] to [acc/2, acc] to prevent unbounded functions from destroying the algorithm.
            let d = cos(atan(scaledDeriv)) * accuracy
            let deltaX = max(d, accuracy / 2)
            x += Double(deltaX)
        }

        // Remove points that are irrelevant to the graph.
        // These are points which are outside the pixel area and both of whose neighbors are outside the pixel area, therefore both produced lines will be invisible.
        let selfRelevant = result.map(scatterPlot.pixelContentRect.contains)
        let leftRelevant = [false] + selfRelevant.dropLast(1)
        let rightRelevant = selfRelevant.dropFirst(1) + [false]

        let relevant = zip(selfRelevant, zip(leftRelevant, rightRelevant)).map { $0 || $1.0 || $1.1 }
        let irrelevantIndices = relevant.indices.filter { !relevant[$0] }

        result.remove(atIndices: irrelevantIndices)

        /* TODO: use this if performance of functional approach is bad
        // Remove points that are irrelevant to the graph.
        // These are points which are outside the pixel area and both of whose neighbors are outside the pixel area, therefore both produced lines will be invisible.
        var prelastInvalid = false // (= false -> prevents removing pre-first point at invalid index)
        var lastInvalid = true

        // Traverse the array backwards
        for (i, point) in result.enumerated().reversed() {
            let invalid = scatterPlot.pixelContentRect.contains(point)

            // Remove last point if three in a row are invalid (the last point is the middle point)
            if prelastInvalid && lastInvalid && invalid {
                result.remove(at: i + 1)
            }

            // Shift validity states
            prelastInvalid = lastInvalid
            lastInvalid = invalid
        }

        // Remove very first point if invalid
        if prelastInvalid && lastInvalid { result.removeFirst() }
        */

        return PolygonalChainStrokable(points: result)
    }
}

fileprivate struct PolygonalChainStrokable: Strokable {
    let points: [CGPoint]

    /// Stroke the quadratic curve defined by the three control points `point1`, `point2` and `point3`.
    func stroke(onto context: CGContext) {
        context.beginPath()
        context.addLines(between: points)
        context.strokePath()
    }
}

