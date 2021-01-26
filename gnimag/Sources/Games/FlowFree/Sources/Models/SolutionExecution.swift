//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// SolutionExecution describes the order and exact way of how the different paths of a Solution should be drawn on the device.
/// This is relevant because optimal orders of execution minimize the distance traveled between end points of consecutive targets. Also, cells in the path of a solution execution may be omitted to generate faster executions, i.e. with fewer direction changes.
struct SolutionExecution {
    /// The execution of a path. Each path execution corresponds to one path from the original solution.
    struct PathExecution {
        /// The color of the path.
        let color: GameColor

        /// The cells the execution consists of, in this order.
        /// These also contain the `begin` and `end` positions.
        /// This is a subset of the cells of the original solution's path. Cells can be omitted to optimize drawing performance.
        /// Also, the direction of the path may be reversed.
        let cells: [Position]

        /// The first cell in the path.
        var begin: Position { cells.first! }

        /// The last cell in the path.
        var end: Position { cells.last! }

        /// Return the reversed path.
        var reversed: PathExecution {
            PathExecution(color: color, cells: cells.reversed())
        }
    }

    /// The paths, ordered by their execution order.
    let pathExecutions: [PathExecution]

    /// Create a SolutionExecution from the given array of PathExecutions.
    init(pathExecutions: [PathExecution]) {
        self.pathExecutions = pathExecutions
    }

    /// Create a SolutionExecution from a solution by executing the solution's paths in an arbitrary order.
    init(solution: Solution) {
        pathExecutions = solution.paths.map { path in
            PathExecution(color: path.color, cells: path.cells)
        }
    }

    /// The total length of the in-air path, i.e. the segments between consecutive PathExecutions.
    var inAirLength: Double {
        zip(pathExecutions, pathExecutions.dropFirst()).map { path, next in
            path.end.distance(to: next.begin)
        }.reduce(0, +)
    }

    /// The summarized total length of the individual PathExecutions.
    var pathLength: Double {
        pathExecutions.map { path in
            zip(path.cells, path.cells.dropFirst()).map { cell, next in
                cell.distance(to: next)
            }.reduce(0, +)
        }.reduce(0, +)
    }
}
