//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// The solution of a level.
struct Solution {
    struct Path {
        let start: Position
        let end: Position

        /// The vertices of the path, i.e. the points where the direction changes.
        let vertices: [Position]
    }

    /// The paths for each color.
    /// Each path belongs to a color – the paths are in the same order as `level.colors` (and therefore has the same size).
    let paths: [Path]

    let level: Level
}
