//
//  Created by David Knothe on 25.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

public final class TapDelayTracker {
    public typealias Time = Double

    /// The image provider, for getting the current time.
    private let imageProvider: ImageProvider

    /// The tracker creating an average value for the delay time.
    private let tracker: PreliminaryTracker

    /// All tap times where a tap has been scheduled at, but not yet detected – i.e. the next detected tap will correspond to the first value in this collection.
    private var scheduledTapTimes = [Time]()

    /// The scheduled tap time of the tap that has been detected most recently.
    /// Used when the current tap detection time is refined.
    private var latestTapTime: Time!

    /// The average delay.
    public var delay: Time? {
        tracker.average
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tolerance: TrackerTolerance) {
        self.imageProvider = imageProvider
        tracker = PreliminaryTracker(tolerance: tolerance)
    }

    /// Call when a tap has just been scheduled.
    public func tapScheduled() {
        scheduledTapTimes.append(imageProvider.time)
    }

    /// Call when a tap has just been detected at the given time.
    /// When no time is passed, the current time of the ImageProvider will be used.
    public func tapDetected(at time: Time? = nil) {
        tracker.finalizePreliminaryValue()

        guard !scheduledTapTimes.isEmpty else { print("EMPTY!"); return }

        // Add delay to tracker preliminarily, as it may be updated lateron (`refineLastTapDetectionTime`)
        latestTapTime = scheduledTapTimes.removeFirst()
        let endTime = time ?? imageProvider.time
        tracker.updatePreliminaryValueIfValid(value: endTime - latestTapTime)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    /// This updates the latest delay value.
    public func refineLastTapDetectionTime(with endTime: Time) {
        guard let startTime = latestTapTime else { print("EMPTY2!"); return }
        tracker.updatePreliminaryValueIfValid(value: endTime - startTime)
    }
}
