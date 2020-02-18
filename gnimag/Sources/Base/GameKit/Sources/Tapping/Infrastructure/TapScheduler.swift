//
//  Created by David Knothe on 27.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// Use TapScheduler from within your tap prediction logic to schedule and reschedule future taps.
public final class TapScheduler {
    public typealias Time = Double

    /// Required instances for tapping and time obtainment.
    private let tapper: Tapper
    private let timeProvider: TimeProvider

    /// The delay tracker which is used to calculate the average total input+output delay.
    /// When you detect a tap, you must inform the delay tracker.
    public let delayTracker: TapDelayTracker

    /// The average tap delay from the delay tracker.
    public var delay: Time? {
        delayTracker.delay
    }

    /// All taps which are currently scheduled (but not yet performed).
    private var scheduledTaps = [Tap]()

    /// All (absolute) times where `tap` has been called at.
    /// Attention: These are not the times where the taps have actually been performed/detected on the device. Therefore, use `actualTapTimes`.
    private var rawPerformedTapTimes = [Time]()

    /// All (absolute) times where a tap has been detected at on device-level. This matches the times where a jump is detected on ImageAnalysis level.
    /// This is just `rawPerformedTapTimes` shifted by `delay`.
    public func actualTapTimes(before bound: Time) -> [Time]? {
        guard let delay = delay else { return nil }
        return rawPerformedTapTimes.map { $0 + delay }.filter { $0 < bound }
    }

    /// An event which is triggered each time a scheduled tap is actually performed.
    /// The time of the tap parameter is not necessarily exactly equal to the actual tap time (i.e. current time) – there could be small deviations (for example if the tap was scheduled for a time in the past).
    public let tapPerformed = Event<Tap>()

    /// Default initializer.
    public init(tapper: Tapper, timeProvider: TimeProvider, tapDelayTolerance: TrackerTolerance) {
        self.tapper = tapper
        self.timeProvider = timeProvider
        delayTracker = TapDelayTracker(tolerance: tapDelayTolerance)
    }

    /// Tap now, creating a new Tap object.
    public func tapNow() {
        let tap = Tap(absoluteTime: timeProvider.currentTime)
        actuallyPerform(tap: tap)
    }

    /// Schedule a single tap in the future.
    public func schedule(tap: Tap) {
        let distance = tap.absoluteTime - timeProvider.currentTime
        if distance < 0 {
            Terminal.log(.warning, "TapScheduler – `schedule` called with a negative time interval (\(distance)). Tap will be executed immediately.")
        }

        scheduledTaps.append(tap)

        Timing.perform(after: distance, identification: .object(self, string: "\(tap.absoluteTime)")) {
            self.actuallyPerform(tap: tap)
        }
    }

    /// Unschedule a previously scheduled tap.
    /// Returns `true` if the tap has been unscheduled.
    /// When returning false, the tap has either never been scheduled, or has already been performed.
    @discardableResult
    public func unschedule(tap: Tap) -> Bool {
        let result = Timing.cancelTasks(matching: .object(self, string: "\(tap.absoluteTime)"))
        scheduledTaps.removeAll { tap == $0 }
        return result
    }

    /// Clear all currently scheduled taps.
    public func unscheduleAll() {
        Timing.cancelTasks(withObject: self)
        scheduledTaps.removeAll()
    }

    /// Perform a tap at the current moment.
    private func actuallyPerform(tap: Tap) {
        let tapTime = timeProvider.currentTime

        tapper.tap()
        delayTracker.tapPerformed(time: tapTime)

        // Update tap arrays and reference time
        rawPerformedTapTimes.append(tapTime)
        scheduledTaps.removeAll { tap == $0 }

        tapPerformed.trigger(with: tap)
    }
}
