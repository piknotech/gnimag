//
//  Created by David Knothe on 25.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// TapDelayTracker considers taps which have been performed, e.g. by TapScheduler, and calculates the average delay from performing the tap to detection of this tap, which is the total input+output delay.
public final class TapDelayTracker {
    public typealias Time = Double

    /// The tracker creating an average value for the delay time.
    private let tracker: PreliminaryTracker

    /// All tap times where a tap has been performed at, but not yet detected – i.e. the next detected tap will correspond to the first value in this collection.
    private var performedTaps = [Time]()

    /// The tap time of the tap that has been detected most recently.
    /// Used when the current tap detection time is refined.
    private var latestTapTime: Time!

    /// The average delay.
    public var delay: Time? {
        tracker.average
    }

    /// The variance of the tap delay tracker.
    public var variance: Time? {
        tracker.variance
    }

    /// Default initializer.
    public init(tolerance: TrackerTolerance) {
        tracker = PreliminaryTracker(tolerancePoints: 0, tolerance: tolerance)
    }

    /// Call when a tap has just been performed at the given time.
    public func tapPerformed(time: Time) {
        performedTaps.append(time)
    }

    /// Call when a tap has just been detected at the given time.
    public func tapDetected(at endTime: Time) {
        // Finalize previous tap
        tracker.finalizePreliminaryValue()
        latestTapTime = nil

        guard !performedTaps.isEmpty else { return } // TODO: error detection / fallback mechanism

        // Add delay to tracker preliminarily, as it may be updated lateron (`refineLastTapDetectionTime`)
        latestTapTime = performedTaps.removeFirst()
        tracker.updatePreliminaryValueIfValid(value: endTime - latestTapTime)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    /// This updates the latest delay value.
    public func refineLastTapDetectionTime(with endTime: Time) {
        guard let startTime = latestTapTime else { return }
        tracker.updatePreliminaryValueIfValid(value: endTime - startTime)
    }
}
