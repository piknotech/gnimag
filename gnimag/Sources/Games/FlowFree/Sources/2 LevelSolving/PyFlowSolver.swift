//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import FlowFreeC
import Foundation

/// A wrapper around the pyflowsolver script.
enum PyFlowSolver {
    private static let scriptLocation = NSHomeDirectory() +/ "Library/Application Support/gnimag/FlowFree/pyflowsolver.py"

    /// Try solving a level (synchronously!) using the pyflowsolver script.
    /// When an error occurs (i.e. python is not installed), it is logged to the console.
    static func solve(level: Level) -> Solution? {
        let input = PyFlowConverter.convertInput(level: level)
        let cmd = "/usr/bin/python \"\(scriptLocation)\" \(input)"

        return cmd.withCString {
            let output = String(cString: execute_cmd($0))

            // Convert output to solution
            guard let result = PyFlowConverter.convertOutput(string: output, for: level) else {
                Terminal.log(.error, "pyflowsolver didn't run successfully. Output:\n\(output)")
                return nil
            }

            return result
        }
    }
}

/// Converts inputs and outputs to and from pyflowsolvers format specifications.
private enum PyFlowConverter {
    static let background: Character = "."
    static let colors: [Character] = Array("ABCDEFGHIJKLMNOP")

    /// Convert the level to the correct input format for pyflowsolver.
    /// This includes storing the board to a (temporary) file. Return the location of the file.
    static func convertInput(level: Level) -> String {
        // The board is indexed via [y][x]
        var board = [[String]](repeating: [String](repeating: String(background), count: level.boardSize), count: level.boardSize)

        for (colorIndex, color) in level.colors.enumerated() {
            for position in [color.start, color.end] {
                board[position.y][position.x] = String(colors[colorIndex])
            }
        }

        // Write board to temporary file
        let boardString = board.map { $0.joined() }.joined(separator: "\n")
        let file = NSTemporaryDirectory() +/ UUID().uuidString
        try! boardString.write(toFile: file, atomically: true, encoding: .utf8)

        return file
    }

    /// Convert the solution string from pyflowsolver to a Solution.
    static func convertOutput(string: String, for level: Level) -> Solution? {
        // Convert string to board array cotaining the color indices
        let board = string.split(separator: "\n").map { line -> [Int] in
            line.compactMap { colors.firstIndex(of: $0) }
        }

        // Validate board size
        if (board.any { $0.count != level.boardSize } || board.count != level.boardSize) { return nil }

        func findPath(forColorIndex colorIndex: Int) -> Solution.Path? {
            let color = level.colors[colorIndex]

            // Verify that solution colors match board colors
            guard board[color.start.y][color.start.x] == colorIndex && board[color.end.y][color.end.x] == colorIndex else {
                Terminal.log(.error, "Solution is invalid, colors dont match with original level")
                return nil
            }

            if let vertices = Self.vertices(from: color.start, to: color.end, previous: nil, in: board) {
                return Solution.Path(start: color.start, end: color.end, vertices: vertices)
            } else {
                Terminal.log(.error, "Solution is invalid, can't trace path for color \(colorIndex)")
                return nil
            }
        }

        // Find path for each color
        let paths = (0 ..< level.colors.count).compactMap(findPath(forColorIndex:))
        if paths.count != level.colors.count { return nil }

        return Solution(paths: paths)
    }

    /// Find the vertices for the path from `start` to `end`, where `previous` is the position directly before `start` in the path.
    /// Board is indexed via board[y][x].
    private static func vertices(from start: Position, to end: Position, previous: Position?, in board: [[Int]]) -> [Position]? {
        guard board[start.y][start.x] == board[end.y][end.x] else { return nil }

        // Trivial case
        if start == end { return [] }

        // Find next neighbor
        var neighbors = sameColoredNeighbors(of: start, in: board)
        neighbors.removeAll { $0 == previous }
        guard neighbors.count == 1 else { return nil }
        let next = neighbors.first!

        // Decide wheter `start` is a vertex (i.e. the path changes direction) or not
        var isVertex = false
        if let previous = previous { // The start of the path is not a vertex
            isVertex = !(previous.x == next.x || previous.y == next.y) // Straight line (A,B,C) --> B is no vertex
        }

        // Recursive call
        guard let furtherPath = vertices(from: next, to: end, previous: start, in: board) else { return nil }
        return (isVertex ? [start] : []) + furtherPath
    }

    /// Find the neighboring positions that have the same color.
    private static func sameColoredNeighbors(of p: Position, in board: [[Int]]) -> [Position] {
        let candidates = [Position(x: p.x-1, y: p.y), Position(x: p.x+1, y: p.y), Position(x: p.x, y: p.y-1), Position(x: p.x, y: p.y+1)]

        return candidates.filter {
            if $0.y < 0 || $0.y >= board.count || $0.x < 0 || $0.x >= board[$0.y].count { return false }
            return board[$0.y][$0.x] == board[p.y][p.x]
        }
    }
}
