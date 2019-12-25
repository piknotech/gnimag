//
//  Created by David Knothe on 25.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public final class TapDelayTracker {
    public typealias Time = Double

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
    public init(tolerance: TrackerTolerance) {
        tracker = PreliminaryTracker(tolerancePoints: 0, tolerance: tolerance)
    }

    /// Call when a tap has just been scheduled at the given time.
    public func tapScheduled(time: Time) {
        scheduledTapTimes.append(time)
    }

    /// Call when a tap has just been detected at the given time.
    public func tapDetected(at endTime: Time) {
        // Finalize previous tap
        tracker.finalizePreliminaryValue()
        latestTapTime = nil

        guard !scheduledTapTimes.isEmpty else { return } // TODO: error detection / fallback mechanism

        // Add delay to tracker preliminarily, as it may be updated lateron (`refineLastTapDetectionTime`)
        latestTapTime = scheduledTapTimes.removeFirst()
        tracker.updatePreliminaryValueIfValid(value: endTime - latestTapTime)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    /// This updates the latest delay value.
    public func refineLastTapDetectionTime(with endTime: Time) {
        guard let startTime = latestTapTime else { return }
        tracker.updatePreliminaryValueIfValid(value: endTime - startTime)
    }
}
