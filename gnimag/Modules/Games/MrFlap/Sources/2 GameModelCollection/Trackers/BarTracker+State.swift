//
//  Created by David Knothe on 13.02.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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

    /// The inner and outer height trackers, for early yCenter guessing.
    let innerHeightTracker = LinearTracker(tolerance: .absolute(0))
    let outerHeightTracker = LinearTracker(tolerance: .absolute(0))

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
            holeSizeWasConstant = false
        }

        // We don't have integrity failures in appearing state
        return true
    }

    func update(with bar: Bar, at time: Double) {
        constantHoleSize.add(value: bar.holeSize)
        innerHeightTracker.add(value: bar.innerHeight, at: time)
        outerHeightTracker.add(value: bar.outerHeight, at: time)
        
        if holeSizeWasConstant {
            yCenterData.append((value: bar.yCenter, time: time))
        }
    }
}

/// Normal state: normally update holeSize and yCenter.
final class BarTrackerStateNormal: BarTrackerState {
    unowned let tracker: BarTracker

    init(tracker: BarTracker) {
        self.tracker = tracker
    }

    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        tracker.holeSize.isValueValid(bar.holeSize, &tracker.debug.holeSize) &&
        tracker.yCenter.integrityCheck(with: bar.yCenter, at: time, &tracker.debug.yCenter)
    }

    func update(with bar: Bar, at time: Double) {
        tracker.holeSize.add(value: bar.holeSize, at: time)
        tracker.yCenter.add(value: bar.yCenter, at: time)
    }
}
