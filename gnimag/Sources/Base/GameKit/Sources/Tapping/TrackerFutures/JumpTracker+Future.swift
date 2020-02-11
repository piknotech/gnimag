//
//  Created by David Knothe on 11.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

public extension JumpTracker {
    /// A structure describing where a jump has started.
    struct JumpStart {
        public let value: Value
        public let time: Time

        /// Default initializer.
        public init(value: Value, time: Time) {
            self.value = value
            self.time = time
        }
    }

    /// Calculate the (last) jump that will be generated when performing jumps at the given times.
    /// The `times` array contains **both** the demanded future times, and the jumps that were made in the past:
    /// It should contain all jumps that were made during the history (or a reasonable period) of this JumpTracker. This is required to compensate for incertainties like not-yet-available regressions or segment start times.
    func finalFutureJumpUsingJumpTimes(times: [Time], overlapTolerance: Time) -> JumpStart? {
        guard let initialJump = initialJumpStart() else { return nil }
        guard let parabola = parabola else { return nil }

        // Time-direction-specific handling
        guard let direction = monotonicityChecker.direction.intValue else { return nil }
        let smaller: (Time, Time) -> Bool = (direction > 0) ? (<) : (>)
        let smallerEqual: (Time, Time) -> Bool = (direction > 0) ? (<=) : (>=)

        // Remove irrelevant (too far in the past) time values
        var times = times.sorted(by: smaller)
        times.dropWhile { smallerEqual($0, initialJump.time + overlapTolerance) }

        // Perform a jump for each remaining time value
        var currentJump = initialJump
        for time in times {
            currentJump = advance(jump: currentJump, whenJumpingAt: time, parabola: parabola)
        }

        return currentJump
    }

    /// The jump that will be used as a starting point for calculations.
    /// This is the latest jump segment having a supposedStartTime and a regression.
    private func initialJumpStart() -> JumpStart? {
        // Find latest segment having a supposedStartTime and a regression
        let allSegments = [currentSegment!] + finalizedSegments.reversed()
        guard let goodSegment = (allSegments.first { $0.supposedStartTime != nil && $0.tracker.regression != nil }) else { return nil }

        let startTime = goodSegment.supposedStartTime!
        let startValue = goodSegment.tracker.regression!.at(startTime)

        return JumpStart(value: startValue, time: startTime)
    }

    /// Jump at the given time, generating a new JumpStart from the given JumpStart.
    /// Or, simpler: Calculate where the given jump current is at the given time.
    private func advance(jump: JumpStart, whenJumpingAt time: Time, parabola: Parabola) -> JumpStart {
        let timeDiff = time - jump.time
        let valueDiff = parabola.at(timeDiff)

        return JumpStart(value: jump.value + valueDiff, time: jump.time + timeDiff)
    }
}
