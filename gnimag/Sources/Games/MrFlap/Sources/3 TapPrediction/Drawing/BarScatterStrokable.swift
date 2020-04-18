//
//  Created by David Knothe on 15.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit
import TestingTools

/// BarScatterStrokable strokes a `PlayerBarInteraction` onto a time/height-plot (like JumpSequencePlot).
struct BarScatterStrokable: ScatterStrokable {
    let interaction: PlayerBarInteraction

    /// Return a MultiStrokable consisting of multiple lines and curves.
    func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        // Bounds curves
        let left = interaction.boundsCurves.left.scatterStrokable
        let right = interaction.boundsCurves.right.scatterStrokable

        // Movement sections
        let sections = interaction.holeMovement.sections.flatMap(\.boundaryStrokables)

        let all = [left, right] + sections
        return MultiScatterStrokable(components: all).concreteStrokable(for: frame)
    }
}

// MARK: Extensions for Creating ScatterStrokables

private extension PlayerBarInteraction.BoundsCurves.Curve {
    /// Create a ScatterStrokable drawing `self`.
    var scatterStrokable: ScatterStrokable {
        ArbitraryFunctionScatterStrokable(function: function, drawingRange: range, interpolationPoints: 25)
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
