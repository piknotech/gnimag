//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

extension Level {
    struct PathBegin {
        /// The index of the color, respective to `self.colors`.
        let colorIndex: Int

        /// True if the path begins at `color.start`, false if it begins at `color.end`.
        let isColorStart: Bool
    }

    /// Calculate the best order in which to successively trace the paths. Best means that the total traveled distance (between consecutive colors, i.e. from color1.end to color2.start etc.) is minimized.
    /// The result is an array of color indices describing the optimal color ordering.
    /// Notice: the best path does not depend on the actual solution but only on the level.
    var bestPathTracingOrder: [PathBegin] {
        // Greedy algorithm: try starting at each of the 2 * colors.count valid positions
        let possibleStartStates = (Array(0 ..< colors.count) × [true, false]).map { (colorIndex, isColorStart) -> (State, PathBegin) in
            let outgoingPosition = isColorStart ? colors[colorIndex].end : colors[colorIndex].start
            return (
                State(usedColors: [colorIndex], pathLength: 0, position: outgoingPosition),
                PathBegin(colorIndex: colorIndex, isColorStart: isColorStart)
            )
        }

        let paths = possibleStartStates.map { (state, pathBegin) in
            bestPath(currentPath: [pathBegin], currentState: state)
        }

        // Return shortest path
        return paths.min { $0.1 < $1.1 }!.0
    }

    /// Calculate the (nearly) best path proceeding from the current state, using a greedy algorithm.
    /// Return the final path and its length.
    private func bestPath(currentPath: [PathBegin], currentState: State) -> ([PathBegin], Double) {
        // Trivial case
        if currentState.usedColors.count == colors.count { return (currentPath, currentState.pathLength) }

        // Find nearest neighbor(s) (greedy)
        let remainingColors = Array(0 ..< colors.count).filter { !currentState.usedColors.contains($0) }
        let possibleNeighbors = (remainingColors × [true, false]).map { (colorIndex, isColorStart) -> (Int, Bool, Position, Double) in
            let incomingPosition = isColorStart ? colors[colorIndex].start : colors[colorIndex].end
            let outgoingPosition = isColorStart ? colors[colorIndex].end : colors[colorIndex].start
            return (colorIndex, isColorStart, outgoingPosition, distance(from: currentState.position, to: incomingPosition))
        }

        // Use nearest neighbor – if there are more than one, discard the othersmin()!
        let bestNeighbor = possibleNeighbors.min { $0.3 < $1.3 }!
        let neighbors = [bestNeighbor] // Could be more than 1 element, but then exponential runtime

        // Calculate bestPath for the nearest neighbor
        let paths = neighbors.map { (colorIndex, isColorStart, position, distance) -> ([PathBegin], Double) in
            // Call `bestPath` recursively
            let newState = State(
                usedColors: currentState.usedColors + [colorIndex],
                pathLength: currentState.pathLength + distance,
                position: position
            )
            let pathBegin = PathBegin(colorIndex: colorIndex, isColorStart: isColorStart)
            return bestPath(currentPath: currentPath + [pathBegin], currentState: newState)
        }

        // Return shortest path
        return paths.min { $0.1 < $1.1 }!
    }

    private func distance(from a: Position, to b: Position) -> Double {
        sqrt(Double((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)))
    }

    private struct State {
        /// The colors that are already used. Includes the color at the current position.
        let usedColors: [Int]

        /// The current length of the path.
        let pathLength: Double

        /// The current (outgoing) position on the board.
        let position: Position
    }
}
