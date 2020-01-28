//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

/// JumpingProperties bundles properties describing the jump environment.
struct JumpingProperties {
    /// The jump parabola, with f(0) = 0, f'(0) = jumpVelocity and f''(x) = -gravity.
    let parabola: Polynomial

    /// The gravity of the environment; the leading factor of the jump polynomial is -1/2*g.
    var gravity: Double {
        -2 * parabola.a
    }

    /// The velocity in y-direction that the object has at the jump start.
    var jumpVelocity: Double {
        parabola.b
    }

    /// The horizontal length of a jump (from jump start until the object is on the same level again).
    var horizontalJumpLength: Double {
        2 * horizontalApexDistance
    }

    /// The x-distance from jump start until reaching the maximum.
    var horizontalApexDistance: Double {
        jumpVelocity / gravity
    }

    /// The maximum height that is reached during a jump.
    /// This equals `0.5 * jumpVelocity * jumpVelocity / gravity`.
    var jumpHeight: Double {
        parabola.at(horizontalApexDistance)
    }

    // MARK: Conversion

    /// Create JumpingProperties from the given player tracker.
    init?(player: PlayerCourse) {
        guard
            let converter = PlayerAngleConverter(player: player),
            let parabola = player.height.parabola else { return nil }

        // Convert from player-angle time system into real time system
        self.parabola = converter.timeBasedPolynomialIgnoringIntercept(from: parabola)
    }
}
