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

    /// All tap times where a tap has been performed at by the TapScheduler.
    public private(set) var performedTaps = [Time]()

    /// An event which is triggered each time a scheduled tap is actually performed.
    public let tapPerformed = Event<Tap>()

    /// Default initializer.
    public init(tapper: Tapper, imageProvider: ImageProvider, tapDelayTolerance: TrackerTolerance) {
        self.tapper = tapper
        self.imageProvider = imageProvider
        delayTracker = TapDelayTracker(tolerance: tapDelayTolerance)
    }

    /// Tap now, creating a new Tap object.
    public func tap() {
        let tap = Tap(time: 0)
        actuallyPerform(tap: tap)
    }

    /// Clear all scheduled taps.
    public func clearScheduledTaps() {
        Timing.cancelPerform(object: self)
    }

    /// Schedule a single tap in the future.
    public func schedule(tap: Tap) {
        guard tap.time >= 0 else {
            Terminal.log(.warning, "TapScheduler – time interval must be positive, is \(tap.time)!")
            return
        }

        Timing.perform(after: tap.time, object: self) {
            self.actuallyPerform(tap: tap)
        }
    }

    /// Perform a tap at the current moment.
    private func actuallyPerform(tap: Tap) {
        let tapTime = imageProvider.time
        tapper.tap()

        // Inform delay tracker and trigger event
        delayTracker.tapPerformed(time: tapTime)
        performedTaps.append(tapTime)

        tapPerformed.trigger(with: tap)
    }
}
