//
//  Created by David Knothe on 23.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import TestingTools

/// BarTracker bundles trackers for a single bar.
final class BarTracker {
    static var momventBoundCollector: BarMovementBoundCollector!

    /// Orphanage detector to see whether the bar tracker should be removed from the game model.
    let orphanage = BarTrackerOrphanageDetector()

    /// The state the bar is currently in.
    /// Only trackers with a "normal" state should be considered by prediction algorithms.
    var state: BarTrackerState!

    // The angle and the center of the hole. yCenter is only used in state "normal".
    let angle: AngularWrapper<LinearTracker>
    let yCenter: BasicLinearPingPongTracker

    // The constant width and hole size.
    let width: ConstantTracker
    let holeSize: ConstantTracker

    /// The shared playfield.
    private let playfield: Playfield

    /// The debug logger and a shorthand form for the current debug frame.
    let debugLogger: DebugLogger
    var debug: DebugLoggerFrame.GameModelCollection._Bar { debugLogger.currentFrame.gameModelCollection.bars.current }

    // Default initializer.
    init(playfield: Playfield, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.debugLogger = debugLogger

        angle = AngularWrapper(LinearTracker(tolerance: .absolute(3% * .pi)))
        width = ConstantTracker(tolerance: .relative(10%))
        holeSize = ConstantTracker(tolerance: .relative(5%))
        yCenter = BasicLinearPingPongTracker(
            tolerance: Self.circularTolerance(dy: 0.5% * playfield.freeSpace, on: playfield),
            slopeTolerance: .relative(40%),
            boundsTolerance: .absolute(5% * playfield.freeSpace),
            decisionCharacteristics: .init(
                pointsMatchingNextSegment: 4,
                maxIntermediatePointsMatchingCurrentSegment: 1
            )
        )

        state = BarTrackerStateAppearing(tracker: self)
    }

    /// Return a circular tolerance with the given dy value, such that `dx ≈ dy * factor`, assuming that the playfield's directions are equivalent (i.e. x-direction = y-direction)
    /// This tolerance depends on the time <-> pixel-position conversion factor.
    private static func circularTolerance(dy: Double, on playfield: Playfield, factor: Double = 100%) -> TrackerTolerance {
        // Movement conversion from angle <-> pixel-position: [0, 2pi] <-> [0, 2pi*r]
        let midRadius = (playfield.innerRadius + playfield.fullRadius) / 2
        let dx = factor * dy / midRadius
        return .absolute2D(dy: dy, dx: dx)
    }

    // MARK: Updating

    /// Check if all given values match the trackers.
    /// NOTE: This changes the state if necessary.
    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        guard angle.isDataPointValid(value: bar.angle, time: time, &debug.angle) else { return false }
        guard width.isValueValid(bar.width, &debug.width) else { return false }

        // State-specific integrityCheck
        // Extend lifetime as state may be changed (i.e. dereferenced) within its own integrityCheck
        return withExtendedLifetime(state) {
            state.integrityCheck(with: bar, at: time)
        }
    }

    /// Update the trackers with the values from the given bar.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with bar: Bar, at time: Double) {
        debug.integrityCheckSuccessful = true

        orphanage.markBarAsValid()

        angle.add(value: bar.angle, at: time)
        width.add(value: bar.width)

        // State-specific update
        state.update(with: bar, at: time)

        // Update shared movement bounds
        BarTracker.momventBoundCollector.update(with: self)
    }

    /// Call before calling `integrityCheck` to prepare the debug logger for receiving debug information for this tracker.
    func setupDebugLogging() {
        debugLogger.currentFrame.gameModelCollection.bars.nextBar()
    }

    /// Write information about the trackers into the current debug logger frame.
    /// Call after the updating has finished, i.e. after `update` or after `integrityCheck`.
    func performDebugLogging() {
        debug.state = state
        debug.angle.from(tracker: angle)
        debug.width.from(tracker: width)
        debug.holeSize.from(tracker: holeSize)
        debug.yCenter.from(tracker: yCenter)
    }
}

extension BarTracker: Hashable {
    static func == (lhs: BarTracker, rhs: BarTracker) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
