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

    /// Default initializer.
    public init(function: Function, drawingRange: SimpleRange<Double>, interpolationPoints: Int) {
        self.function = function
        self.drawingRange = drawingRange
        self.interpolationPoints = interpolationPoints
    }

    /// Return the concrete strokable for drawing onto a specific ScatterPlot.
    public func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        let pixelRect = scatterPlot.pixelContentRect
        let dataRect = scatterPlot.dataContentRect

        // Calculate range
        let start = max(drawingRange.lower, Double(dataRect.minX))
        let end = min(drawingRange.upper, Double(dataRect.maxX))
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
            let yStretch = pixelRect.height / dataRect.height
            let xStretch = pixelRect.width / dataRect.width
            let scaledDeriv = deriv * yStretch / xStretch

            // d is the x-delta to exactly go `accuracy` pixels on the graph.
            // We transform d from [0, acc] to [acc/2, acc] to prevent unbounded functions from destroying the algorithm.
            let d = cos(atan(scaledDeriv)) * accuracy
            let deltaX = max(d, accuracy / 2)
            x += Double(deltaX)
        }

        // Add point at the end of the interval
        let last = scatterPlot.pixelPosition(of: (end, function.at(end)))
        result.append(last)

        // Remove points that are irrelevant to the graph.
        // These are points which are outside the pixel area and both of whose neighbors are outside the pixel area, therefore both produced lines will be invisible.
        let selfRelevant = result.map(pixelRect.contains)
        let leftRelevant = [false] + selfRelevant.dropLast(1)
        let rightRelevant = selfRelevant.dropFirst(1) + [false]

        let relevant = zip(selfRelevant, zip(leftRelevant, rightRelevant)).map { $0 || $1.0 || $1.1 }
        let irrelevantIndices = relevant.indices.filter { !relevant[$0] }

        // Convert into connected components
        var components = [[CGPoint]]()
        for index in irrelevantIndices.reversed() {
            let right = Array(result[(index+1)...]) // Right from the splitting point is a connected component
            if !right.isEmpty { components.append(right) }
            result.removeLast(result.count - index) // Remove the component and the splitting point
        }

        // Last component
        if !result.isEmpty { components.append(result) }

        return PolygonalChainsStrokable(chains: components)
    }
}

fileprivate struct PolygonalChainsStrokable: Strokable {
    let chains: [[CGPoint]]

    /// Stroke all polygonal chains.
    func stroke(onto context: CGContext) {
        context.beginPath()

        for chain in chains {
            context.addLines(between: chain)
            context.strokePath()
        }
    }
}

