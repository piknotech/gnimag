//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

/// JumpingProperties bundles properties describing the jump environment.
struct JumpingProperties {
    /// The velocity in y-direction that the object has at the jump start.
    let jumpVelocity: Double

    /// The gravity of the environment; the leading factor of the jump polynomial is -1/2*g.
    let gravity: Double

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

    /// The jump parabola, with f(0) = 0, f'(0) = jumpVelocity and f''(x) = -gravity.
    var parabola: Polynomial {
        Polynomial([0, jumpVelocity, -0.5 * gravity])
    }

    // MARK: Conversion

    /// Read JumpingProperties from a player tracker.
    static func from(player: PlayerCourse) -> JumpingProperties? {
        guard
            let speed = player.angle.tracker.slope,
            let gravity = player.height.gravity,
            let jumpVelocity = player.height.jumpVelocity else { return nil }

        // Convert from player-angle time system into real time system
        let realGravity = gravity * speed * speed
        let realJumpVelocity = jumpVelocity * speed

        return JumpingProperties(jumpVelocity: realJumpVelocity, gravity: realGravity)
    }
}
