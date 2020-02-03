//
//  Created by David Knothe on 27.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// Use TapScheduler from within your tap prediction logic to schedule and reschedule future taps.
public final class TapScheduler {
    public typealias Time = Double

    /// The tapper and imageProvider, for tapping and time obtainment.
    private let tapper: Tapper
    private let imageProvider: ImageProvider

    /// The delay tracker which is used to calculate the average total input+output delay.
    /// When you detect a tap, you must inform the delay tracker.
    public let delayTracker: TapDelayTracker

    /// The average tap delay from the delay tracker.
    public var delay: Time? {
        delayTracker.delay
    }

    /// All taps which are currently scheduled (but not yet performed).
    public private(set) var scheduledTaps = [Tap]()

    /// All (absolute) times where a tap has been performed at.
    public private(set) var performedTapTimes = [Time]()

    /// An event which is triggered each time a scheduled tap is actually performed.
    /// The time of the tap parameter is not necessarily exactly equal to the actual tap time (i.e. current time) – there could be small deviations (for example if the tap was scheduled for a time in the past).
    public let tapPerformed = Event<Tap>()

    /// Default initializer.
    public init(tapper: Tapper, imageProvider: ImageProvider, tapDelayTolerance: TrackerTolerance) {
        self.tapper = tapper
        self.imageProvider = imageProvider
        delayTracker = TapDelayTracker(tolerance: tapDelayTolerance)
    }

    /// Tap now, creating a new Tap object.
    public func tapNow() {
        let tap = Tap(absoluteTime: imageProvider.time)
        actuallyPerform(tap: tap)
    }

    /// Schedule a single tap in the future.
    public func schedule(tap: Tap) {
        let distance = tap.absoluteTime - imageProvider.time
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
        let tapTime = imageProvider.time

        tapper.tap()
        delayTracker.tapPerformed(time: tapTime)

        // Update tap arrays and reference time
        performedTapTimes.append(tapTime)
        scheduledTaps.removeAll { tap == $0 }

        tapPerformed.trigger(with: tap)
    }
}