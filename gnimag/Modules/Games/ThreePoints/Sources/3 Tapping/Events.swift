//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit

protocol Event {
    var absoluteTime: Double { get }
}

/// CollisionWithDot describes a collision of the prism with a dot.
/// This collision can either be in the future (when predicting), or in the past, when .
struct CollisionWithDot: Event {
    /// The absolute time of the collision.
    let absoluteTime: Double
    let dotColor: DotColor

    /// Used to distinguish two CollisionWithDots.
    let tracker: DotTracker

    /// Default initializer. If there is no regression, return nil.
    init?(playfield: Playfield, tracker: DotTracker) {
        guard let regression = tracker.yCenter.regression,
            let collisionTime = LinearSolver.solve(regression, equals: playfield.prism.collisionY) else { return nil }

        absoluteTime = collisionTime
        dotColor = tracker.color
        self.tracker = tracker
    }
}

/// PrismRotation describes the begin of a prism rotation, triggered through a tap.
struct PrismRotation: Event {
    /// The absolute time of the begin of the rotation.
    let absoluteTime: Double
}
