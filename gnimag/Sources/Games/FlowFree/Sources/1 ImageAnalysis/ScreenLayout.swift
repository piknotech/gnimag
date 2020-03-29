//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry

/// The exact layout of elements on the screen.
/// Useful for both image analysis and tapping.
struct ScreenLayout {
    /// The on-screen layout of the board.
    let board: BoardLayout

    /// The total size of the screen.
    /// Important: The size of the screen must not change throughout the game.
    let screenSize: CGSize
}

/// The on-screen layout of the board.
struct BoardLayout {
    let aabb: AABB

    /// The number of boxes per row or per column.
    let size: Int

    /// The center of the cell at the given (x/y) position (0-based).
    func center(ofCell cell: (x: Int, y: Int)) -> CGPoint {
        let x = Double(2 * cell.x + 1) / Double(2 * size)
        let y = Double(2 * cell.y + 1) / Double(2 * size)
        return CGPoint(x: x, y: y)
    }
}
