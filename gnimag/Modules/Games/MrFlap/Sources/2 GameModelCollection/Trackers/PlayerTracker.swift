//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit

/// PlayerTracker bundles trackers for the player position which is defined by angle and height.
final class PlayerTracker {
    private let playfield: Playfield

    /// The angle and height trackers.
    /// For angle tracking, the normal game time is used. For height tracking, the player angle is used.
    let angle: AngularWrapper<LinearTracker>
    let height: JumpTracker

    /// The size of the player.
    let size: ConstantTracker

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.GameModelCollection._Player { debugLogger.currentFrame.gameModelCollection.player }

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.debugLogger = debugLogger

        angle = AngularWrapper(LinearTracker(tolerance: .absolute(7% * .pi)))
        height = JumpTracker(
            jumpTolerance: Self.circularTolerance(dy: 2% * playfield.freeSpace, on: playfield),
            relativeValueRangeTolerance: 10%,
            consecutiveNumberOfPointsRequiredToDetectJump: 2,
            idleHeightBeforeInitialSegment: initialPlayer.height
        )
        size = ConstantTracker(tolerance: .relative(20%))

        height.assumeNoInvalidDataPoints = true
    }

    /// Return a circular tolerance with the given dy value, such that `dx ≈ dy * factor`, assuming that the playfield's directions are equivalent (i.e. x-direction = y-direction)
    /// This tolerance depends on the time <-> pixel-position conversion factor.
    private static func circularTolerance(dy: Double, on playfield: Playfield, factor: Double = 100%) -> TrackerTolerance {
        // Movement conversion from angle <-> pixel-position: [0, 2pi] <-> [0, 2pi*r]
        let midRadius = (playfield.innerRadius + playfield.fullRadius) / 2
        let dx = factor * dy / midRadius
        return .absolute2D(dy: dy, dx: dx)
    }

    /// Use the player height tracker for tap detection.
    /// Therefore, link the segment switch callbacks to the given TapPredictor.
    func linkPlayerJump(to predictor: TapPredictor) {
        // For tap delay tracking, the actual time (from imageProvider) is required.
        // Because player jump tracking is performed using the player's angle, it first has to be converted back to an (approximate) time value.
        func convertPlayerAngleToTime(playerAngle: Double) -> Double? {
            PlayerAngleConverter(player: self)?.time(from: playerAngle)
        }

        // Link segment switch callback
        height.advancedToNextSegment += { angle in
            if let time = convertPlayerAngleToTime(playerAngle: angle) {
                predictor.tapDetected(at: time)
            }
        }

        // Link segment startTime update callback
        height.updatedSupposedStartTimeForCurrentSegment += { angle in
            if let angle = angle, let time = convertPlayerAngleToTime(playerAngle: angle) {
                predictor.refineLastTapDetectionTime(with: time)
            }
        }
    }

    // MARK: Updating

    /// Check if all given values match the trackers.
    func integrityCheck(with player: Player, at time: Double) -> Bool {
        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        debug.linearAngle = linearAngle

        return size.isValueValid(player.size, &debug.size) &&
            angle.isDataPointValid(value: player.angle, time: time, &debug.angle) &&
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

    /// Write information about the trackers into the current debug logger frame.
    /// Call after the updating has finished, i.e. after `update` or after `integrityCheck`.
    func performDebugLogging() {
        debug.angle.from(tracker: angle)
        debug.size.from(tracker: size)
        debug.height.from(tracker: height)
    }
}
