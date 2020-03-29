//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry

/// A flow-free level.
struct Level {
    typealias Position = (x: Int, y: Int)
    typealias Color = (start: Position, end: Position)

    /// The array of colors, each of which has a start and an end position.
    let colors: [Color]

    /// The number of boxes per row or per column.
    let boardSize: Int
}

extension Level: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        if lhs.boardSize != rhs.boardSize { return false }
        if lhs.colors.count != rhs.colors.count { return false }

        // Match each lhs-color to an rhs-color
        for color1 in lhs.colors {
            let hasMatch = rhs.colors.any { color2 in
                color1.start == color2.start && color1.end == color2.end ||
                color1.start == color2.end && color1.end == color2.start
            }
            if !hasMatch { return false }
        }

        return true
    }
}
