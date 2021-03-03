//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// Board represents the game board at an arbitrary state.
/// This means, each cell can either be empty or filled with a color.
struct Board: LosslessStringConvertible {
    /// The 2D board array, which is indexed via `board[y][x]`.
    /// This format corresponds to the human-readable form.
    private var board: [[GameColor?]]

    /// The size, i.e. both the number of rows and the number of columns.
    var size: Int { board.count }

    /// Create an empty board.
    init(size: Int) {
        board = [[GameColor?]](repeating: [GameColor?](repeating: nil, count: size), count: size)
    }

    /// Create a board from a level.
    init(level: Level) {
        self.init(size: level.boardSize)

        for (color, target) in level.targets {
            for point in [target.point1, target.point2] {
                self[point] = color
            }
        }
    }

    /// Access the cell at the given position.
    subscript(position: Position) -> GameColor? {
        get { board[position.y][position.x] }
        set { board[position.y][position.x] = newValue }
    }

    /// Determine whether the cell at the given position is a target cell of a level.
    func isTargetCell(at position: Position, level: Level) -> Bool {
        guard let color = self[position], let target = level.targets[color] else { return false }
        return position == target.point1 || position == target.point2
    }

    /// Check whether a position is contained on the board.
    func contains(_ position: Position) -> Bool {
        position.x >= 0 && position.x < size && position.y >= 0 && position.y < size
    }

    // MARK: String Conversion
    // Example of a half-filled board:
    // AB.C
    // .A.C
    // ...C
    // BCCC

    /// Create a board from a color string. Thereby, the string represents a 2D-board, each color represented by a letter, and each row separated by a newline. A "." means empty cell.
    init?(_ description: String) {
        let rowStrings = Array(description.split(separator: "\n").map(String.init).reversed()) // Flip board in y-direction
        let size = rowStrings.count
        guard (rowStrings.allSatisfy { $0.length == size }) else { return nil }

        self.init(size: size)

        // Fill board, cell by cell
        for (x, y) in (0 ..< size) × (0 ..< size) {
            let char = rowStrings[y][x]

            if GameColor.allLetters.contains(char) {
                self[Position(x, y)] = GameColor(letter: char)
            } else if char == "." {
                // Do nothing, cell already empty
            } else {
                return nil // Invalid character
            }
        }
    }

    /// Convert a board into its distinct string representation, using newlines as the row separator.
    var description: String {
        stringify(separator: "\n")
    }

    /// Convert a board into its distinct string representation, using a custom separator between consecutive rows.
    /// Thereby, the string represents a 2D-board, each color represented by a letter. A "." means empty cell.
    func stringify(separator: String) -> String {
        let cellToString: (GameColor?) -> String = { cell in
            cell.flatMap { $0.letter } ?? "."
        }

        let rowToString: ([GameColor?]) -> String = { (row) in
            row.map(cellToString).joined()
        }

        let allRowStrings = board.map(rowToString).reversed() // Flip in y-direction to make board human readable (i.e. (0,0) is lower-left)
        return allRowStrings.joined(separator: separator)
    }

    /// Return all neighbors of a given cell which are on the board.
    /// The content of the cells is not considered.
    func neighbors(of cell: Position) -> [Position] {
        let candidates = [Position(cell.x+1, cell.y), Position(cell.x-1, cell.y), Position(cell.x, cell.y+1), Position(cell.x, cell.y-1)]
        return candidates.filter(contains(_:))
    }
}
