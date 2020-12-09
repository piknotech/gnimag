//
//  Created by David Knothe on 05.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

enum TemplateCell {
    case color
    case otherColor
    case otherColorTarget
    case empty
    case dontCare

    /// Determine whether `color` fulfills the template.
    /// Thereby, `mainColor` is the main color of the path.
    func matches(color: GameColor?, mainColor: GameColor, isTarget: Bool) -> Bool {
        switch self {
        case .color:
            return color == mainColor
        case .otherColor:
            return color != nil && color != mainColor
        case .otherColorTarget:
            return /* color != nil && color != mainColor && */ isTarget
        case .empty:
            return color == nil
        case .dontCare:
            return true
        }
    }
}

/// Each ShortcutTemplate defines a possibility for a path contraction.
/// This means, a ShortcutTemplate defines a subpath of a color which, when encountered on a board segment, can be contracted to a straight line from start to end.
/// Thereby, the template also defines the required state of other cells in the rectangular area (i.e. cell must be empty, or cell must not be empty etc.)
///
/// A ShortcutTemplate always follows the following rules:
///  - The start of the path is at (0, 0) (lower-left) and the end is at (w-1, h-1) (upper-right).
///  - The board is wider as it is high (or has equal width and height).
/// When comparing a board segment to a ShortcutTemplate, it must be rotated and flipped to obtain the same properties.
struct ShortcutTemplate {
    /// The 2D template board array, which is indexed via `board[y][x]`.
    private let board: [[TemplateCell]]

    /// The dimensions of the template board.
    let width: Int
    let height: Int

    /// Default initializer.
    /// Fails if the board is not rectangular.
    init(board: [[TemplateCell]]) {
        self.board = board

        height = board.count
        width = board[0].count
        precondition(board.allSatisfy { $0.count == width })
    }

    /// Get the template cell at a given position.
    func at(_ position: Position) -> TemplateCell {
        board[position.y][position.x]
    }

    /// Determine whether the template is fulfilled by the given board segment.
    /// Therefore, the segment must have the same dimensions and every board cell must match the respective template.
    func matches(segment: BoardSegment, color mainColor: GameColor, level: Level) -> Bool {
        if width != segment.width || height != segment.height { return false }

        // Check each cell
        for (x, y) in (0 ..< width) × (0 ..< height) {
            let position = Position(x, y)

            let template = at(position)
            let color = segment.at(position)
            let isTarget = segment.isTargetCell(at: position, level: level)

            if !template.matches(color: color, mainColor: mainColor, isTarget: isTarget) { return false }
        }

        return true
    }
}
