//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerCourse bundles trackers for the player position which is defined by angle and height.
final class PlayerCourse {
    /// The angle and height trackers.
    /// For angle tracking, the normal game time is used. For height tracking, the player angle is used.
    let angle = AngularWrapper(LinearTracker())
    let height: JumpTracker

    /// The size of the player.
    let size = ConstantTracker()

    /// Default initializer.
    init(playfield: Playfield) {
        height = JumpTracker(
            relativeValueRangeTolerance: 20%,
            absoluteJumpTolerance: 2% * playfield.freeSpace,
            consecutiveNumberOfPointsRequiredToDetectJump: 2,
            customGuessRange: SimpleRange<Double>(from: 0, to: 0)
        )
    }

    // MARK: Updating

    /// Update the trackers with the values from the given player.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with player: Player, at time: Double) {
        angle.add(value: player.angle, at: time)
        size.add(value: player.size)

        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        height.add(value: player.height, at: linearAngle) // Use angle instead of time to account for small lags (which are really dangerous for exact jump tracking)
    }

    /// Check if all given values match the trackers.
    func integrityCheck(with player: Player, at time: Double) -> Bool {
        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        return
            angle.is(player.angle, at: time, validWith: .absolute(tolerance: 2% * .pi)) &&
            size.is(player.size, validWith: .relative(tolerance: 10%)) &&
            height.integrityCheck(with: player.height, at: linearAngle)
    }
}
