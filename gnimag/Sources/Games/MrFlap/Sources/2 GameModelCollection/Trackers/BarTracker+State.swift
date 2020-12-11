//
//  Created by David Knothe on 13.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

protocol BarTrackerState: CustomStringConvertible {
    /// Perform a state-specific integrity check; return the result of the integrity check.
    /// You can change the state of the BarTracker. When doing this, "update" will not be called on this object, but on the new state object.
    func integrityCheck(with bar: Bar, at time: Double) -> Bool

    /// Perform a state-specific update.
    /// Do not change the state of the BarTracker from inside this method.
    func update(with bar: Bar, at time: Double)
}

extension BarTrackerState {
    /// Description for debug logging.
    var description: String {
        let typeName = "\(type(of: self))"
        let baseName = "BarTrackerState"
        return typeName.replacingOccurrences(of: baseName, with: "")
    }
}

// BarTracker has the following states (arrows mean possible state transitions):
// appearing -> normal <-> decideDisappearing -> disappearing

/// Appearing state: wait until 3 consecutive "normal" frames (i.e. with constant hole size) happen, then switch to normal state.
final class BarTrackerStateAppearing: BarTrackerState {
    unowned let tracker: BarTracker

    init(tracker: BarTracker) {
        self.tracker = tracker

        // Use same tolerance as BarTracker
        constantHoleSize = ConstantTracker(tolerancePoints: 0, tolerance: tracker.holeSize.tolerance)
    }

    /// After the hole size stays constant for 3 frames, appearing state has ended.
    private let constantHoleSize: ConstantTracker
    private var consecutiveFramesWithConstantHoleSize = 0

    /// Data points that can immediately be transferred to the yCenter tracker on state switch.
    private var yCenterData = [(value: Double, time: Double)]()

    /// The last inner and outer height values, for early yCenter guessing.
    var lastInnerAndOuterHeights: (Double, Double)?

    var holeSizeWasConstant = false

    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        if constantHoleSize.isValueValid(bar.holeSize, fallback: .invalid) {
            consecutiveFramesWithConstantHoleSize += 1

            // State switch after 3 consecutive normal frames
            if consecutiveFramesWithConstantHoleSize == 3 {
                tracker.state = BarTrackerStateNormal(tracker: tracker)
                yCenterData.forEach(tracker.yCenter.add(value:at:))
            }

            holeSizeWasConstant = true
        }

        // Hole size doesn't match
        else {
            constantHoleSize.reset()
            yCenterData.removeAll()
            consecutiveFramesWithConstantHoleSize = 0
            lastInnerAndOuterHeights = nil
            holeSizeWasConstant = false
        }

        // We don't have integrity failures in appearing state
        return true
    }

    func update(with bar: Bar, at time: Double) {
        constantHoleSize.add(value: bar.holeSize)
        lastInnerAndOuterHeights = (bar.innerHeight, bar.outerHeight)
        if holeSizeWasConstant {
            yCenterData.append((value: bar.yCenter, time: time))
        }
    }
}

/// Normal state: normally update holeSize and yCenter.
/// When holeSize is too large, switch to decision (between normal and disappearing) state.
final class BarTrackerStateNormal: BarTrackerState {
    unowned let tracker: BarTracker

    init(tracker: BarTracker) {
        self.tracker = tracker
    }

    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        // Normal validity check
        if tracker.holeSize.isValueValid(bar.holeSize, &tracker.debug.holeSize) {
            return tracker.yCenter.integrityCheck(with: bar.yCenter, at: time, &tracker.debug.yCenter)
        }

        else {
            // Hole size didn't match – if too high, go to BarTrackerStateDecideDisappearing state
            if bar.holeSize > tracker.holeSize.average ?? 0 {
                tracker.state = BarTrackerStateDecideDisappearing(tracker: tracker)
                return true
            }

            // If hole size was too low, an integrity error has happened
            else {
                return false
            }
        }
    }

    func update(with bar: Bar, at time: Double) {
        tracker.holeSize.add(value: bar.holeSize, at: time)
        tracker.yCenter.add(value: bar.yCenter, at: time)
    }
}

/// After holeSize was too high in normal state, go into this state to decide whether the bar is actually disappearing or not.
/// Switch either back to normal or disappearing state.
final class BarTrackerStateDecideDisappearing: BarTrackerState {
    unowned let tracker: BarTracker

    init(tracker: BarTracker) {
        self.tracker = tracker
    }

    /// After the hole size is too large for 3 frames, disappearing state will begin.
    private var consecutiveNumberOfFramesWithTooLargeHoleSize = 0

    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        // If holeSize is valid again, go back to normal state
        if tracker.holeSize.isValueValid(bar.holeSize, &tracker.debug.holeSize) {
            tracker.state = BarTrackerStateNormal(tracker: tracker)
            return tracker.state.integrityCheck(with: bar, at: time)
        }

        else {
            // Hole size is either too large or too low
            if bar.holeSize > tracker.holeSize.average ?? 0 {
                consecutiveNumberOfFramesWithTooLargeHoleSize += 1
            } else {
                // Hole size too low – go back to normal state
                tracker.state = BarTrackerStateNormal(tracker: tracker)
                return tracker.state.integrityCheck(with: bar, at: time)
            }

            // State switch after 3 consecutive disapparing frames
            if consecutiveNumberOfFramesWithTooLargeHoleSize == 3 {
                tracker.state = BarTrackerStateDisappearing()
            }

            // Don't trigger erroneous integrity check failures
            return true
        }
    }

    func update(with bar: Bar, at time: Double) {
    }
}

/// In disappearing state, the bar is not interesting anymore.
/// Do nothing, and return true for integrityCheck (to avoid false integrity check errors).
final class BarTrackerStateDisappearing: BarTrackerState {
    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        true
    }

    func update(with bar: Bar, at time: Double) {
    }
}
