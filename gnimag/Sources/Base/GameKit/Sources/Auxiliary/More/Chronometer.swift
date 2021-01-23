//
//  Created by David Knothe on 11.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import QuartzCore

/// Chronometer allows very simple and well-typed execution of timing measurements of different events.
/// Timing averages can be extracted per event.
public class Chronometer<Event: CaseIterable & Hashable> {
    /// The measurement trackers, one per event.
    public private(set) var measurementTrackers = [Event: ConstantTracker]()

    /// The absolute start time values of running measurements.
    private var measurementStartTimes = [Event: Double]()

    /// The measured event duration in this frame.
    private var currentFrameDurations = [Event: Double]()

    /// Default initializer.
    public init(maxMeasurementsPerEvent: Int = 1000) {
        for event in Event.allCases {
            measurementTrackers[event] = ConstantTracker(maxDataPoints: maxMeasurementsPerEvent, tolerancePoints: 0)
        }
    }

    /// Begin a measurement for an event.
    /// If there is already a measurement running for an event, restart it if `restart = true`, else ignore this call and continue the running measurement.
    public func start(_ event: Event, restart: Bool = true) {
        if restart || measurementStartTimes[event] == nil {
            measurementStartTimes[event] = CACurrentMediaTime()
        }
    }

    /// Call `start` with multiple events at once.
    public func start(_ events: [Event], restart: Bool = true) {
        for event in events {
            start(event, restart: restart)
        }
    }


    /// Finish a running measurement for an event.
    /// If there is no running measurement, ignore this call, but log a warning.
    /// Return the timing value of this measurement.
    @discardableResult
    public func stop(_ event: Event, logWarning: Bool = true) -> Double? {
        if let startTime = measurementStartTimes[event] {
            let difference = CACurrentMediaTime() - startTime
            measurementTrackers[event]!.add(value: difference)
            measurementStartTimes[event] = nil
            currentFrameDurations[event] = difference
            return difference
        }
        else if logWarning {
            Terminal.log(.warning, "Chronometer: no running measurement for event \(event)")
        }

        return nil
    }

    /// Measure the execution time of a block for an event. Return the result of the block.
    @discardableResult
    public func measure<R>(_ event: Event, block: () -> R) -> R {
        start(event, restart: true)
        let result = block()
        stop(event)
        return result
    }

    /// Get the average value for an event. If there is no finished measurement for this event yet, return nil.
    public func averageMeasurement(for event: Event) -> Double? {
        measurementTrackers[event]?.average
    }

    /// Reset the current-frame event measurements.
    public func newFrame() {
        currentFrameDurations.removeAll()
    }

    /// Return the current-frame measurement for a given event, or nil if the event was not yet measured during this frame.
    public func currentMeasurement(for event: Event) -> Double? {
        currentFrameDurations[event]
    }
}
