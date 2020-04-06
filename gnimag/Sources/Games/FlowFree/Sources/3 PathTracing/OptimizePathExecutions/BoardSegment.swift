//
//  Created by David Knothe on 05.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import ImageAnalysisKit

/// BoardSegment is a rectangular section of a board, possibly flipped and rotated by a multiple of 90°.
/// A BoardSegment is always constructed in such that way (i.e. flipped and rotated) that it has the properties that are required by ShortcutTemplate:
///  - The start of the path is at (0, 0) (lower-left) and the end is at (w-1, h-1) (upper-right).
///  - The segment is higher as it is wide (or has equal width and height).
struct BoardSegment {
    /// The original board.
    private let board: Board

    /// The location of (0,0) on the original board.
    private let origin: Position

    /// When true, changes to the queried x-coordinate translate to changes to the y-coordinate on the original board and vice versa.
    private let xyFlipped: Bool

    /// When increasing the x-coordinate (AFTER applying xyFlipped), the x-coordinate is increased by xDirection (-1 or +1).
    private let xDirection: Int
    private let yDirection: Int

    /// The effective width and height of the segment.
    let width: Int
    let height: Int

    /// Create a BoardSegment containing a path from a start to an end position. Thereby, it is constructed so that `start` is at (0, 0) and `end` is at (w-1, h-1). Also, the segment is higher as it is wide (or has equal width and height).
    init(from start: Position, to end: Position, in board: Board) {
        self.board = board

        let direction = end - start
        origin = start

        width = abs(direction.dx) + 1
        height = abs(direction.dy) + 1
        xyFlipped = width > height

        xDirection = direction.dx.signum()
        yDirection = direction.dy.signum()
    }

    /// Get the color at the relative positon in the board segment.
    func at(_ position: Position) -> GameColor? {
        return board[absolutePosition(for: position)]
    }

    /// Determine whether the cell at the given position is a target cell of a level.
    func isTargetCell(at position: Position, level: Level) -> Bool {
        let pos = absolutePosition(for: position)
        return board.isTargetCell(at: pos, level: level)
    }

    /// Convert a position from BoardSegment coordinates to the coordinates of the original board.
    private func absolutePosition(for relative: Position) -> Position {
        let dx = xyFlipped ? relative.y : relative.x
        let dy = xyFlipped ? relative.x : relative.y
        let offset = Delta(dx * xDirection, dy * yDirection)
        return origin + offset
    }
}
