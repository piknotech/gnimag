//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry

/// Player describes the position of the bird.
struct Player {
    /// The position of the player, repsective to the playfield's center.
    let coords: PolarCoordinates
    var angle: Double { Double(coords.angle) }
    var height: Double { Double(coords.height) }
    
    /// The width and height of the quadratic bird.
    let size: Double
}
