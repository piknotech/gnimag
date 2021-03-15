//
//  Created by David Knothe on 13.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation
import Geometry

/// Playfield describes the position and the dimensions of the playfield on the screen.
struct Playfield {
    /// The center of the line where the dots fall down.
    let dotCenterX: Double

    /// The position of the prism.
    let prism: Prism
    struct Prism {
        let circumcircle: Circle

        /// Side length of the equilateral triangle.
        var sideLength: Double { sqrt(3) * Double(circumcircle.radius) }

        /// When a dot has this (or a lower) y-center, it collides with the prism. This is also the top of the aligned prism.
        var collisionY: Double { Double(circumcircle.center.y + circumcircle.radius / 2) }
    }
}
