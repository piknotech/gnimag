//
//  Created by David Knothe on 03.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import ImageAnalysisKit

extension SolutionExecution {
    /// Return a SolutionExecution by optimizing the individual PathExecutions, i.e. by removing cells which cause unnecessary turns.
    /// In other words, this speeds up the execution by replacing paths that just consist of right-angled turns with more aggressive paths (i.e. Shortcuts) which minimally intersect other cells, and have, in total, less turns and a smaller length.
    func optimizePathExecutions(level: Level) -> SolutionExecution {
        var currentBoard = Board(level: level) // Start with empty board

        let result = pathExecutions.map { path -> PathExecution in
            for cell in path.cells { currentBoard[cell] = path.color } // Update board
            return optimize(path: path, level: level, currentBoard: currentBoard)
        }

        print("before: \(pathLength), after: \(SolutionExecution(pathExecutions: result).pathLength)")
        return SolutionExecution(pathExecutions: result)
    }

    /// Optimize a single PathExecution by the means described above.
    /// `currentBoard` is the board filled with all already drawn paths and the path that is considered currently (i.e. `path`).
    private func optimize(path: PathExecution, level: Level, currentBoard: Board) -> PathExecution {
        var result = path.cells
        var i = 0

        outer: while i < result.count {
            for j in (i+1) ..< result.count {
                if canLinearizePath(from: result[i], to: result[j], in: currentBoard, length: j-i, level: level, color: path.color) {
                    continue // Increase j -> check next cell
                }
                else {
                    // Path segment from i to j-1 can be linearized.
                    // Then, continue with i=j (which is actually just i+1, because everything between i and j has been removed)
                    linearize(path: &result, from: i, to: j-1)
                    i += 1
                    continue outer
                }
            }

            // We are only here when j == result.count, i.e. all cells from i to j can be linearized
            linearize(path: &result, from: i, to: result.count - 1)
            break
        }

        return PathExecution(color: path.color, cells: result)
    }

    /// Decide whether the path from `start` to `end` can be linearized, e.g. replaced by just the path `[start, end]`.
    private func canLinearizePath(from start: Position, to end: Position, in board: Board, length: Int, level: Level, color: GameColor) -> Bool {
        // Check for straight line
        let diff = start - end
        if (diff.dx == 0 || diff.dy == 0) && max(abs(diff.dx), abs(diff.dy)) == length { return true }

        // Create BoardSegment and compare to all known ShortcutTemplates
        let segment = BoardSegment(from: start, to: end, in: board)
        return Shortcuts.all.any {
            $0.matches(segment: segment, color: color, level: level)
        }
    }

    /// Contract the path so that positions i and j remain unchanged, and everything between is removed.
    private func linearize(path: inout [Position], from i: Int, to j: Int) {
        if i+1 < j {
            path.removeSubrange((i+1) ..< j)
        }
    }
}
