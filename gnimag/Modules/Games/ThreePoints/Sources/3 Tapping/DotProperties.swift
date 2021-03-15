//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// DotProperties describe a single moving live dot.
struct DotProperties {
    /// The duration until colliding with the prism.
    let collisionWithPrism: Double

    /// Default initializer. If there is no regression, return nil.
    init?(playfield: Playfield, tracker: DotTracker) {
        collisionWithPrism = 0
    }
}
