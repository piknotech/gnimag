//
//  Created by David Knothe on 27.12.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// Use TapScheduler from within your tap prediction logic to schedule and reschedule future taps.
public final class TapScheduler {
    private let timing = Timing()

    /// Required instances for tapping and time obtainment.
    private let tapper: SomewhereTapper
    private let timeProvider: TimeProvider

    /// The delay tracker which is used to calculate the average total input+output delay.
    /// When you detect a tap, you must inform the delay tracker.
    public let delayTracker: TapDelayTracker

    /// The average tap delay from the delay tracker.
    public var delay: Double? {
        delayTracker.delay
    }

    /// All taps that are currently scheduled but have not yet been performed.
    public private(set) var scheduledTaps = [ScheduledTap]()

    /// All taps that have actually been performed.
    public private(set) var performedTaps = [PerformedTap]()

    /// The expected detection times of the taps at the CURRENT timepoint, i.e. using the CURRENT delay.
    public func lastExpectedDetectionTimes(num: Int) -> [Double] {
        performedTaps.suffix(num).compactMap { tap in
            delay.flatMap { tap.performedAt + $0 } ?? tap.expectedDetectionTime
        }
    }

    /// An event which is triggered each time a scheduled tap is actually performed.
    /// This is called after the `performedTaps` array has been updated.
    public let tapPerformed = Event<PerformedTap>()

    /// Default initializer.
    public init(tapper: SomewhereTapper, timeProvider: TimeProvider, tapDelayTolerance: TrackerTolerance) {
        self.tapper = tapper
        self.timeProvider = timeProvider
        delayTracker = TapDelayTracker(tolerance: tapDelayTolerance)
    }

    /// Create a new RelativeTap object and tap immediately.
    public func tapNow() {
        schedule(tap: RelativeTap(scheduledIn: 0))
    }

    /// Schedule a single tap in the future.
    public func schedule(tap: RelativeTap) {
        // Create ScheduledTap from RelativeTap
        let t = timeProvider.currentTime
        let scheduledTap = ScheduledTap(
            relativeTap: tap,
            referenceTime: t,
            expectedDetectionTime: delay.map { t + tap.relativeTime + $0 }
        )
        scheduledTaps.append(scheduledTap)

        // Perform tap either immediately or schedule it
        if tap.relativeTime == 0 {
            self.actuallyPerform(scheduledTap)
        } else {
            timing.perform(after: tap.relativeTime, identification: .object(scheduledTap)) {
                self.actuallyPerform(scheduledTap)
            }
        }
    }

    /// Unschedule a previously scheduled tap.
    /// Returns `true` if the tap has been unscheduled.
    /// When returning false, the tap has either never been scheduled or has already been performed.
    @discardableResult
    public func unschedule(tap: ScheduledTap) -> Bool {
        let result = timing.cancelTasks(matching: .object(tap))
        scheduledTaps.removeAll { tap === $0 }
        return result
    }

    /// Clear all currently scheduled taps.
    public func unscheduleAll() {
        timing.cancelAllTasks()
        scheduledTaps.removeAll()
    }

    /// Perform a tap at the current moment.
    private func actuallyPerform(_ tap: ScheduledTap) {
        tapper.tap()

        let performedTap = PerformedTap(scheduledTap: tap)
        delayTracker.tapPerformed(performedTap)

        // Update arrays and trigger event
        scheduledTaps.removeAll { $0 === tap }
        performedTaps.append(performedTap)

        tapPerformed.trigger(with: performedTap)
    }
}
