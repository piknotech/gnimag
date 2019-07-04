//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Player describes the position of the bird.

struct Player {
    /// The center of the player, repsective to the playfield's center.
    let height: Double
    let angle: Double
    
    /// The width and height of the quadratic bird.
    let size: Double
}
