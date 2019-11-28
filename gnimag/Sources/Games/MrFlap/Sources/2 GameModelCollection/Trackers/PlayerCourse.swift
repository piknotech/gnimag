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
    let angle: AngularWrapper<LinearTracker>
    let height: JumpTracker

    /// The size of the player.
    let size: ConstantTracker

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugLoggerFrame.GameModelCollection._Player { debugLogger.currentFrame.gameModelCollection.player }

    /// Default initializer.
    init(playfield: Playfield, debugLogger: DebugLogger) {
        angle = AngularWrapper(LinearTracker(tolerance: .absolute(2% * .pi)))
        height = JumpTracker(
            relativeValueRangeTolerance: 20%,
            absoluteJumpTolerance: 1% * playfield.freeSpace,
            consecutiveNumberOfPointsRequiredToDetectJump: 2,
            customGuessRange: SimpleRange<Double>(from: 0, to: 0)
        )
        size = ConstantTracker(tolerance: .relative(10%))

        self.debugLogger = debugLogger
    }

    // MARK: Updating

    /// Update the trackers with the values from the given player.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with player: Player, at time: Double) {
        debug.integrityCheckSuccessful = true

        angle.add(value: player.angle, at: time)
        size.add(value: player.size)

        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        height.add(value: player.height, at: linearAngle) // Use angle instead of time to account for small lags (which are really dangerous for exact jump tracking)
    }

    /// Check if all given values match the trackers.
    func integrityCheck(with player: Player, at time: Double) -> Bool {
        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        performDebugLogging(linearAngle: linearAngle)

        return angle.isDataPointValid(value: player.angle, time: time, &debug.angle) &&
            size.isValueValid(player.size, &debug.size) &&
            height.integrityCheck(with: player.height, at: linearAngle, &debug.height)
    }

    /// Write information about the trackers into the current debug logger frame.
    private func performDebugLogging(linearAngle: Double) {
        debug.linearAngle = linearAngle
        debug.angle.from(tracker: angle)
        debug.size.from(tracker: size)
        debug.height.from(tracker: height)
    }
}
