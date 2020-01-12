//
//  Created by David Knothe on 27.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Dispatch
import Image
import Tapping

/// Use TapScheduler from within your tap prediction logic to schedule and reschedule future taps.
public final class TapScheduler {
    public typealias Time = Double

    /// The tapper and imageProvider, for tapping and time obtainment.
    private let tapper: Tapper
    private let imageProvider: ImageProvider

    /// The delay tracker which is used to calculate the average total input+output delay.
    /// You must inform it about detected taps.
    public let delayTracker: TapDelayTracker

    /// The average tap delay from the delay tracker.
    public var delay: Time? {
        delayTracker.delay
    }

    /// All tap times where a tap has been performed at by the TapScheduler.
    public private(set) var performedTaps = [Time]()

    /// Default initializer.
    public init(tapper: Tapper, imageProvider: ImageProvider, tapDelayTolerance: TrackerTolerance) {
        self.tapper = tapper
        self.imageProvider = imageProvider
        delayTracker = TapDelayTracker(tolerance: tapDelayTolerance)
    }

    /// Tap now.
    public func tap() {
        let tapTime = imageProvider.time
        tapper.tap()

        delayTracker.tapPerformed(time: tapTime)
        performedTaps.append(tapTime)
    }

    /// Schedule a tap in the future.
    public func scheduleTap(in time: Time) {
        if time <= 0 {
            Terminal.log(.warning, "TapScheduler – time interval must be positive, is \(time)!")
            return
        }

        // ...
    }
}
