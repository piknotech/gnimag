//
//  Created by David Knothe on 23.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import ImageAnalysisKit
import TestingTools

/// BarTracker bundles trackers for a single bar.
final class BarTracker {
    /// Orphanage detector to see whether the bar tracker should be removed from the game model.
    let orphanage = BarTrackerOrphanageDetector()

    /// The state the bar is currently in.
    /// Only trackers with an "appearing" or "normal" state should be considered by prediction algorithms.
    var state: BarTrackerState!

    var isDisappearing: Bool {
        state is BarTrackerStateDisappearing
    }

    /// Triggered when the bar switches to disappearing state, or when it was detected to be orphaned.
    let disappearedOrOrphaned = Event<Void>()

    // The angle and the center of the hole. yCenter is only used in state "normal".
    let angle: AngularWrapper<LinearTracker>
    let yCenter: BasicLinearPingPongTracker

    // The constant width and hole size.
    let width: ConstantTracker
    let holeSize: ConstantTracker

    /// The shared playfield.
    private let playfield: Playfield

    /// The colors that this bar has. The color does not change.
    /// This is used to distinguish bars when the theme color changes, i.e. old bars disappear and new bars appear.
    private let color: ColorMatch

    /// The debug logger and a shorthand form for the current debug frame.
    let debugLogger: DebugLogger
    var debug: DebugFrame.GameModelCollection._Bar { debugLogger.currentFrame.gameModelCollection.bars.current }

    // Default initializer.
    init(playfield: Playfield, color: ColorMatch, movement: FineBarMovementCharacter, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.color = color
        self.debugLogger = debugLogger

        let slopeGuess = BarCenterSlopeGuesses.guess(for: movement) * playfield.fullRadius

        angle = AngularWrapper(LinearTracker(tolerance: .absolute(5% * .pi)))
        width = ConstantTracker(tolerance: .relative(20%))
        holeSize = ConstantTracker(tolerance: .relative(5%))
        yCenter = BasicLinearPingPongTracker(
            tolerance: Self.circularTolerance(dy: 0.5% * playfield.freeSpace, on: playfield),
            slopeTolerance: .relative(50%),
            replacementForFirstSegmentSlopeValue: slopeGuess,
            boundsTolerance: .absolute(5% * playfield.freeSpace),
            decisionCharacteristics: .init(
                pointsMatchingNextSegment: 6,
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

        // Trigger disappearing event after the state has possibly changed in the state-specific integrityCheck
        let wasDisappearing = isDisappearing
        defer {
            if !wasDisappearing && isDisappearing {
                disappearedOrOrphaned.trigger()
            }
        }

        // State-specific integrityCheck
        // Extend lifetime as state may be changed (i.e. dereferenced) within its own integrityCheck
        return withExtendedLifetime(state) {
            state.integrityCheck(with: bar, at: time)
        }
    }

    /// Update the trackers with the values from the given bar.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with bar: Bar, at time: Double) {
        // Important: if the color doesn't match, the bar may or may not be the correct one. Definitely don't update, and let OrphanageDetector do its thing.
        // We could already return "false" on integrityCheck, but that would trigger wrong integrityError logging.
        if !color.matches(bar.color) { return }

        debug.integrityCheckSuccessful = true

        orphanage.markBarAsValid()

        angle.add(value: bar.angle, at: time)
        width.add(value: bar.width)

        // State-specific update
        state.update(with: bar, at: time)
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

    // MARK: Future yCenter SegmentPortions

    /// When the bar is either appearing or has no yCenter regression yet, construct a sensible dummy segment portion which consists of the current yCenter value or, if the bar is appearing, the predicted yCenter value.
    func fallbackSegmentPortion(gmc: GameModelCollector, timeRange: SimpleRange<Double>) -> BasicLinearPingPongTracker.LinearSegmentPortion {
        var yCenter = rawFallbackYCenter(gmc: gmc)

        // Trim to switch bounds
        let (lowerBound, upperBound) = gmc.barPhysicsRecorder.switchValues(for: self)
        yCenter = min(max(yCenter, lowerBound), upperBound)

        let line = LinearFunction(slope: 0, intercept: yCenter)
        return BasicLinearPingPongTracker.LinearSegmentPortion(index: 0, timeRange: timeRange, line: line)
    }

    /// The fallback yCenter, untrimmed.
    private func rawFallbackYCenter(gmc: GameModelCollector) -> Double {
        // 1. There already is a yCenter value, but no regression
        if let value = yCenter.currentSegment?.tracker.values.last {
            return value
        }

        // 2. Use inner and outer height regressions from appearing state to guess the yCenter
        let state = self.state as! BarTrackerStateAppearing
        let holeSize = gmc.barPhysicsRecorder.holeSize(for: self)
        if let inner = state.innerHeightTracker.regression, let outer = state.outerHeightTracker.regression {
            let t = LinearSolver.solve(inner + outer, equals: playfield.freeSpace - holeSize)!
            return inner.at(t) + holeSize / 2
        }

        // 3. Use last inner and outer heights from appearing state to guess the yCenter
        let inner = state.innerHeightTracker.values.last!
        let outer = state.outerHeightTracker.values.last!
        let t = (playfield.freeSpace - holeSize) / (inner + outer)
        return inner * t + holeSize / 2
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
