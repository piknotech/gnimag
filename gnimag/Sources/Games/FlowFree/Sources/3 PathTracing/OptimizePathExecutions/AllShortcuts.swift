//
//  Created by David Knothe on 05.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// The following characters are used to illustrate template cells:
/// - X: main color
/// - O: target cell of other color
/// - o: arbitrary cell (target or path) of other color
/// - -: empty
/// -  : dont care (everything allowed)
private extension TemplateCell {
    init?(character: Character) {
        switch character {
        case "X": self = .color
        case "O": self = .otherColorTarget
        case "o": self = .otherColor
        case "-": self = .empty
        case ".": self = .dontCare
        default: return nil
        }
    }
}

enum Shortcuts {
    /// All possible shortcuts.
    static let all = parse(from: allShortcuts)

    /// Parse a collection of ShortcutTemplates, which is illustrated by a string as demonstrated above.
    private static func parse(from string: String) -> [ShortcutTemplate] {
        var boardStrings = string.components(separatedBy: "\n\n")
        boardStrings.removeAll { $0.starts(with: "//") } // Remove commented boards

        return boardStrings.map {
            guard let result = parse(board: $0) else {
                exit(withMessage: "Couldn't parse ShortcutTemplate from string:\n\($0)")
            }
            return result
        }
    }

    /// Parse a single ShortcutTemplate.
    private static func parse(board: String) -> ShortcutTemplate? {
        let rowStrings = Array(board.split(separator: "\n").map(String.init).reversed()) // Flip board in y-direction

        let cells: [[TemplateCell?]] = rowStrings.map { row in
            row.map(TemplateCell.init(character:))
        }

        // Fail if any character couldn't be parsed
        if (cells.any { $0.any { $0 == nil }}) { return nil }

        let unwrapped = cells.map { $0.compactMap(id) }
        return ShortcutTemplate(board: unwrapped)
    }
}
