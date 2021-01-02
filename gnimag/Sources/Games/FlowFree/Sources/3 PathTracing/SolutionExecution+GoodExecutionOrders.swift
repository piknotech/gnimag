//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

extension SolutionExecution {
    /// Find a set of good (not necessarily very best) execution orders. Execution order means that only the order and direction of paths are altered; not the paths themselves (i.e. no cells are removed from individual paths).
    /// These execution orders try to minimize the total in-air length of the tapping device when drawing the paths in this order and in these directions.
    /// These orders are obtained via a greedy algorithm.
    /// Attention: Not necessarily all of these execution orders are good. Check `inAirLength` to see the respective in-air-lengths of the returned execution paths.
    func goodExecutionOrders() -> [SolutionExecution] {
        let allStartPositions: [(color: GameColor, position: Position, initialPath: PathExecution)] = (pathExecutions × [true, false]).map { path, begin in
            let outgoingPosition = begin ? path.begin : path.end
            let initialExecution = begin ? path.reversed : path
            return (path.color, outgoingPosition, initialExecution)
        }

        // Create best path from each of the starting positions
        let allColors = pathExecutions.map(\.color)
        return allStartPositions.map { color, position, initialExecution -> SolutionExecution in
            let state = State(remainingColors: allColors.removing(color), inAirLength: 0, outgoingPosition: position)
            return SolutionExecution(pathExecutions: [initialExecution] + bestOrder(for: state))
        }
    }

    /// The best (not really) order, starting at the given state (i.e. working with the remaining colors).
    private func bestOrder(for state: State) -> [PathExecution] {
        // Trivial case
        if state.remainingColors.isEmpty { return [] }

        // Dictionary lookup replacement
        let pathForColor: (GameColor) -> PathExecution = { color in
            self.pathExecutions.first { $0.color == color }!
        }

        // Find nearest neighbor
        let neighbors: [(color: GameColor, position: Position)] = cartesianMap(state.remainingColors, [true, false]) { color, begin in
            let startPosition = begin ? pathForColor(color).begin : pathForColor(color).end
            return (color, startPosition)
        }

        // There could be multiple nearest neighbors, but we ignore them and just use any of them
        let nearestNeighbor = neighbors.min {
            $0.position.distance(to: state.outgoingPosition)
        }!

        // Reverse path if required and determine nextOutgoingPosition
        var path = pathForColor(nearestNeighbor.color)
        let isReversed = nearestNeighbor.position == path.end
        if isReversed { path = path.reversed } // Now, path.begin == nearestNeighbor.position

        let nextOutgoingPosition = path.end // The other end of nearestNeighbor's path

        let newState = State(
            remainingColors: state.remainingColors.removing(nearestNeighbor.color),
            inAirLength: state.inAirLength + state.outgoingPosition.distance(to: nearestNeighbor.position),
            outgoingPosition: nextOutgoingPosition
        )

        // Call `bestOrder` recursively to find the remaining path
        let thisExecution = PathExecution(color: nearestNeighbor.color, cells: path.cells)
        return [thisExecution] + bestOrder(for: newState)
    }

    /// The state of the algorithm before or after choosing the next color & position (i.e. PathExecution) to move to.
    private struct State {
        /// The colors that are not used yet.
        let remainingColors: [GameColor]

        /// The current total length of the in-air path, i.e. the segments between consecutive PathExecutions.
        /// PathExecutions itself are not counted (as they remain unaffected by this algorithm).
        let inAirLength: Double

        /// The current position from which the next-best color/PathExecution has to be found.
        let outgoingPosition: Position
    }
}
