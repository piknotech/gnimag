//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// Playfield describes the measures of the playfield.
struct Playfield {
    /// The center of the concentric circles.
    let center: CGPoint

    /// The radius of the inner circle.
    let innerRadius: Double

    /// The radius of the outer circle.
    let fullRadius: Double

    /// The free space in-between the two concentric circles.
    var freeSpace: Double {
        fullRadius - innerRadius
    }
}
