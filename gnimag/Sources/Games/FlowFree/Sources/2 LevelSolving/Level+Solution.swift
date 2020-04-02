//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

extension Level {
    /// Try solving a level (synchronously!) using the pyflowsolver script.
    /// When an error occurs (i.e. python is not installed), it is logged to the console.
    var solution: Solution? {
        if boardSize <= 12 {
            return CFlowSolver.solve(level: self) ?? PyFlowSolver.solve(level: self)
        } else {
            return PyFlowSolver.solve(level: self)
        }
    }
}

/// The solution of a level.
struct Solution {
    struct Path {
        let start: Position
        let end: Position

        /// The vertices of the path, i.e. the points where the direction changes.
        let vertices: [Position]

        /// Return the reversed path, going from `end` to `start`.
        var reversed: Path {
            Path(start: end, end: start, vertices: vertices.reversed())
        }
    }

    /// The paths for each color.
    /// Each path belongs to a color – the paths are in the same order as `level.colors` (and therefore has the same size).
    let paths: [Path]
}
