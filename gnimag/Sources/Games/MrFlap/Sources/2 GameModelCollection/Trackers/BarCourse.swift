//
//  Created by David Knothe on 23.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import TestingTools

/// BarCourse bundles trackers for a single bar.
final class BarCourse {
    static var momventBoundCollector: BarMovementBoundCollector!

    /// The state the bar is currently in.
    /// Only trackers with a "normal" state should be considered by prediction algorithms.
    private(set) var state = State.appearing
    enum State {
        case appearing, normal
    }

    // The angle and the center of the hole. yCenter is only used in state "normal".
    let angle: AngularWrapper<LinearTracker>
    let yCenter: BasicLinearPingPongTracker

    // The constant width and hole size.
    let width: ConstantTracker
    let holeSize: ConstantTracker

    /// The hole size while the bar is appearing.
    /// Only used during the appearing state (which is really short). Once the hole size stays constant, the bar has stopped appearing and the "holeSize" tracker is used.
    let appearingHoleSize: LinearTracker

    /// The shared playfield.
    private let playfield: Playfield

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugLoggerFrame.GameModelCollection._Bar { debugLogger.currentFrame.gameModelCollection.bars.current }

    // Default initializer.
    init(playfield: Playfield, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.debugLogger = debugLogger

        angle = AngularWrapper(LinearTracker(tolerance: .absolute(3% * .pi)))
        width = ConstantTracker(tolerance: .relative(10%))
        holeSize = ConstantTracker(tolerance: .relative(5%))
        appearingHoleSize = LinearTracker(tolerancePoints: 0, tolerance: .absolute(5% * playfield.freeSpace))
        yCenter = BasicLinearPingPongTracker(
            tolerance: .absolute(0.5% * playfield.freeSpace),
            slopeTolerance: .relative(40%),
            boundsTolerance: .absolute(5% * playfield.freeSpace),
            decisionCharacteristics: .init(
                pointsMatchingNextSegment: 4,
                maxIntermediatePointsMatchingCurrentSegment: 1
            )
        )
    }

    // MARK: Updating

    /// Check if all given values match the trackers.
    /// NOTE: This changes the state from `.appearing` to `.normal` when necessary.
    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        guard angle.isDataPointValid(value: bar.angle, time: time, &debug.angle) else { return false }
        guard width.isValueValid(bar.width, &debug.width) else { return false }

        switch state {
        case .appearing:
            // If the appearing hole size does not match (but the angle and width did), the appearing state has ended; switch to normal state
            if !appearingHoleSize.isDataPointValid(value: bar.holeSize, time: time, &debug.appearingHoleSize) {
                print("state switch!")
                debug.stateSwitch = true
                state = .normal
            }

        case .normal:
            return holeSize.isValueValid(bar.holeSize, &debug.holeSize) &&
                yCenter.integrityCheck(with: bar.yCenter, at: time, &debug.yCenter)
        }

        return true
    }

    /// Update the trackers with the values from the given bar.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with bar: Bar, at time: Double) {
        debug.integrityCheckSuccessful = true

        angle.add(value: bar.angle, at: time)
        width.add(value: bar.width)

        switch state {
        case .appearing:
            appearingHoleSize.add(value: bar.holeSize, at: time)

        case .normal:
            holeSize.add(value: bar.holeSize, at: time)
            yCenter.add(value: bar.yCenter, at: time)
        }

        // Update shared movement bounds
        BarCourse.momventBoundCollector.update(with: self)
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
        debug.appearingHoleSize.from(tracker: appearingHoleSize)
        debug.holeSize.from(tracker: holeSize)
        debug.yCenter.from(tracker: yCenter)
    }
}

extension BarCourse: Hashable {
    static func == (lhs: BarCourse, rhs: BarCourse) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
