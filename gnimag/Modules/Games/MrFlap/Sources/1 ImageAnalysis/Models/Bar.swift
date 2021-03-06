//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Image

/// Bar describes the measurements of a vertical bar.
struct Bar {
    /// The width of the bar.
    let width: Double
    
    /// The current angle of the bar, respective to the game's center.
    let angle: Double
    
    /// The height of the solid inner part.
    let innerHeight: Double

    /// The height of the solid outer part.
    let outerHeight: Double

    /// The hole size and the y-center of the hole.
    let holeSize: Double

    /// The y-center, in bar coordinates (ignoring the playfield radius).
    /// This means, yCenter is in [0, playfield.freeSpace].
    var yCenter: Double { innerHeight + holeSize / 2 }
}
