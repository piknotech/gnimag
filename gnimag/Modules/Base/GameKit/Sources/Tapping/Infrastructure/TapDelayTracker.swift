//
//  Created by David Knothe on 25.12.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// TapDelayTracker considers taps which have been performed, e.g. by TapScheduler, and calculates the average delay from when the tap was scheduled for (by TapScheduler) to the detection of this tap, which is the total input+output delay plus the average NSTimer delay.
public final class TapDelayTracker {
    public typealias Time = Double

    /// The tracker creating an average value for the delay time.
    /// Only use it read-only!
    public let tracker: PreliminaryTracker

    /// All taps that have been performed, but not yet detected – i.e. the next detected tap will most likely correspond to the first value in this collection.
    private var performedTaps = [PerformedTap]()

    /// The tap that has been detected most recently.
    /// Used when the current tap detection time is refined.
    private var mostRecentDetectedTap: PerformedTap?

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
        tracker = PreliminaryTracker(maxDataPoints: 10, tolerancePoints: 0, tolerance: tolerance, maxDataPointsForLogging: 1000)
    }

    /// Call when a tap has just been performed at the given time.
    public func tapPerformed(_ tap: PerformedTap) {
        performedTaps.append(tap)
        performedTaps.sort(by: \.scheduledFor)
    }

    /// Call when a tap has just been detected at the given time.
    public func tapDetected(at detectionTime: Time) {
        // Finalize previous tap
        tracker.finalizePreliminaryValue()
        mostRecentDetectedTap = nil

        guard !performedTaps.isEmpty else {
            return Terminal.log(.error, "TapDelayTracker – tap was detected, but no tap was scheduled! Probably someone tapped on the screen")
        }

        // Search first tap in `performedTaps` where the detection time is valid, i.e. the first tap that corresponds to the detected tap.
        // Normally this should be the first tap; only when a tap couldn't be detected, e.g. due to lagging, this is not the first tap.
        guard let tapIndex = (performedTaps.firstIndex { tracker.isValueValid(detectionTime - $0.scheduledFor) }) else {
            performedTaps.removeAll()
            return Terminal.log(.error, "TapDelayTracker – no tap matches the detected time!")
        }

        if tapIndex > 0 {
            Terminal.log(.error, "TapDelayTracker – skipped \(tapIndex) tap(s)")
        }

        performedTaps.removeFirst(tapIndex)
        mostRecentDetectedTap = performedTaps.removeFirst()

        mostRecentDetectedTap!.actualDetectionTime = detectionTime
        tracker.updatePreliminary(value: detectionTime - mostRecentDetectedTap!.scheduledFor)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    /// This updates the latest delay value.
    public func refineLastTapDetectionTime(with detectionTime: Time) {
        guard let tap = mostRecentDetectedTap else { return }
        tap.actualDetectionTime = detectionTime

        if tracker.isValueValid(detectionTime - tap.scheduledFor) {
            tracker.updatePreliminaryValueIfValid(value: detectionTime - tap.scheduledFor)
        } else {
            let diff = tracker.average! - (detectionTime - tap.scheduledFor)
            Terminal.log(.error, "TapDelayTracker – refining last tap time didn't match (diff: \(diff), max allowed: \(tracker.tolerance)")
        }
    }
}
