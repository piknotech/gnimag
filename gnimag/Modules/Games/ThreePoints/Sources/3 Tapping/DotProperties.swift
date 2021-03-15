//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit

/// DotProperties describe a single moving live dot.
struct DotProperties {
    /// The duration until colliding with the prism.
    let collisionWithPrism: Double
    let color: DotColor

    /// Default initializer. If there is no regression, return nil.
    init?(playfield: Playfield, tracker: DotTracker, currentTime: Double) {
        guard let regression = tracker.yCenter.regression,
            let collisionTime = LinearSolver.solve(regression, equals: playfield.prism.collisionY) else { return nil }
        collisionWithPrism = collisionTime - currentTime
        self.color = tracker.color
    }
}
