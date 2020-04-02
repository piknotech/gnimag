//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// A level's solution.
struct Solution {
    /// The solution consists of path, each of which corresponding to a level's target.
    struct Path {
        /// The cells the path consists of, in this order.
        let cells: [Position]
    }

    /// The paths, indexed by their color.
    let paths: [GameColor: Path]

    // MARK: Conversion from Board

    /// Convert a solved Board into a Solution object which matches the given level.
    /// Fails if the Board is not a valid solution to the given level.
    init?(board: Board, level: Level) {
        var paths = [GameColor: Path]()

        // Read solution for each target
        for target in level.targets {
            // Verify that level matches board
            if board[target.point1] != target.color || board[target.point2] != target.color { return nil }

            if let path = Self.path(from: target.point1, to: target.point2, in: board) {
                paths[target.color] = Path(cells: path)
            } else {
                return nil // Target has no solution
            }
        }

        self.paths = paths
    }

    /// Find a path, starting at a given position, moving to a known endpoint.
    private static func path(from current: Position, to end: Position, previous: Position? = nil, in board: Board) -> [Position]? {
        // Trivial case
        if current == end { return [end] }

        // Find next neighbor; there must be exactly one neighbor which is not the previous cell
        var neighbors = board.neighbors(of: current)
        neighbors.removeAll { board[$0] != board[current] } // Consider same-colored neighbors
        neighbors.removeAll { $0 == previous }              // which are not the previous cell
        guard neighbors.count == 1 else { return nil }
        let next = neighbors.first!

        // Recursive call
        guard let furtherPath = path(from: next, to: end, previous: current, in: board) else { return nil }
        return [current] + furtherPath
    }
}
