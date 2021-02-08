//
//  Created by David Knothe on 15.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit
import TestingTools

/// BarScatterStrokable strokes a `PlayerBarInteraction` onto a time/height-plot (like SolutionPlot).
struct BarScatterStrokable: ScatterStrokable {
    let interaction: PlayerBarInteraction

    /// Return a MultiStrokable consisting of multiple lines and curves.
    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let boundary = interaction.partialBoundaryScatterStrokables
        let sections = interaction.holeMovement.sections.flatMap(\.boundaryStrokables)

        let all = boundary + sections
        return MultiScatterStrokable(components: all).concreteStrokable(for: frame)
    }
}

// MARK: Extensions for Creating ScatterStrokables

private extension PlayerBarInteraction {
    /// Create up to 4 ScatterStrokables drawing the outer bounds curves. Thereby, a hole is left in the middle for the range where the hole movement happens.
    var partialBoundaryScatterStrokables: [ScatterStrokable] {
        partialScatterStrokables(for: boundsCurves.left, intersection: holeMovement.intersectionsWithBoundsCurves.left) +
        partialScatterStrokables(for: boundsCurves.right, intersection: holeMovement.intersectionsWithBoundsCurves.right)
    }

    /// Return up to two ScatterStrokables that describe the (either left or right) boundary of the bar. Thereby, a hole is left in the middle for the range where the hole movement happens.
    private func partialScatterStrokables(for curve: BoundsCurves.Curve, intersection: HoleMovement.IntersectionsWithBoundsCurves.IntersectionWithBoundsCurve) -> [ScatterStrokable] {
        let range1 = SimpleRange(from: curve.range.lower, to: intersection.xRange.lower)
        let range2 = SimpleRange(from: intersection.xRange.upper, to: curve.range.upper)

        return [
            ArbitraryFunctionScatterStrokable(function: curve.function, drawingRange: range1, interpolationPoints: 25),
            ArbitraryFunctionScatterStrokable(function: curve.function, drawingRange: range2, interpolationPoints: 25),
        ]
    }
}

private extension PlayerBarInteraction.HoleMovement.Section {
    /// One or two ScatterStrokables defining the lower and upper bounds of this movement section.
    var boundaryStrokables: [ScatterStrokable] {
        [lower, upper].compactMap(\.scatterStrokable)
    }
}

private extension PlayerBarInteraction.HoleMovement.Section.LinearMovement {
    /// Create a ScatterStrokable drawing `self`.
    /// If `self` has no valid range, return nil.
    var scatterStrokable: ScatterStrokable? {
        guard let range = range else { return nil }
        return LinearScatterStrokable(line: line, drawingRange: range)
    }
}
