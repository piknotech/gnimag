//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerCourse bundles trackers for the player position which is defined by angle and height.
final class PlayerCourse {
    private let playfield: Playfield

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
    init(playfield: Playfield, initialPlayer: Player, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.debugLogger = debugLogger

        angle = AngularWrapper(LinearTracker(tolerance: .absolute(2% * .pi)))
        height = JumpTracker(
            relativeValueRangeTolerance: 20%,
            jumpTolerance: .absolute(0), // Will be live-updated lateron
            consecutiveNumberOfPointsRequiredToDetectJump: 2,
            customGuessRange: SimpleRange<Double>(from: 0, to: 0),
            idleHeightBeforeInitialSegment: initialPlayer.height
        )
        size = ConstantTracker(tolerance: .relative(10%))
    }

    /// Use the player height tracker for tap detection.
    /// Therefore, link the segment switch callbacks to the given TapDelayTracker.
    func linkPlayerJump(to tapDelayTracker: TapDelayTracker) {
        // For tap delay tracking, the actual time (from imageProvider) is required.
        // Because player jump tracking is performed using the player's angle, it first has to be converted back to an (approximate) time value.
        func convertPlayerAngleToTime(playerAngle: Double) -> Double? {
            guard let (slope, intercept) = angle.tracker.slopeAndIntercept else { return nil }
            return (playerAngle - intercept) / slope
        }

        // Link segment switch callback
        height.advancedToNextSegment += { angle in
            if let time = convertPlayerAngleToTime(playerAngle: angle) {
                tapDelayTracker.tapDetected(at: time)
            }
        }

        // Link segment startTime update callback
        height.updatedSupposedStartTimeForCurrentSegment += { angle in
            if let angle = angle, let time = convertPlayerAngleToTime(playerAngle: angle) {
                tapDelayTracker.refineLastTapDetectionTime(with: time)
            }
        }
    }

    // MARK: Updating

    /// Check if all given values match the trackers.
    func integrityCheck(with player: Player, at time: Double) -> Bool {
        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        debug.linearAngle = linearAngle

        updateJumpTrackerTolerance()

        return angle.isDataPointValid(value: player.angle, time: time, &debug.angle) &&
            size.isValueValid(player.size, &debug.size) &&
            height.integrityCheck(with: player.height, at: linearAngle, &debug.height)
    }

    /// Update the trackers with the values from the given player.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with player: Player, at time: Double) {
        debug.integrityCheckSuccessful = true

        angle.add(value: player.angle, at: time)
        size.add(value: player.size)

        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        height.add(value: player.height, at: linearAngle) // Use angle instead of time to account for small lags (which are really dangerous for exact jump tracking)
    }

    /// Update the tolerance of the jump tracker so that dx ≈ 25% * dy.
    /// This tolerance depends on the time <-> player-pixel-position conversion factor.
    private func updateJumpTrackerTolerance() {
        let dy = 1% * playfield.freeSpace

        if let angularSpeed = angle.tracker.slope {
            // Movement conversion: time -> angle -> pixel-position:
            // t -> t * angularSpeed -> t * angularSpeed * r
            let midRadius = (playfield.innerRadius + playfield.fullRadius / 2)
            let dydxFactor = abs(angularSpeed) * midRadius
            let dx = 25% * dy / dydxFactor
            height.tolerance = .absolute2D(dy: dy, dx: dx)
        } else {
            height.tolerance = .absolute(dy)
        }
    }

    /// Write information about the trackers into the current debug logger frame.
    /// Call after the updating has finished, i.e. after `update` or after `integrityCheck`.
    func performDebugLogging() {
        debug.angle.from(tracker: angle)
        debug.size.from(tracker: size)
        debug.height.from(tracker: height)
    }
}
