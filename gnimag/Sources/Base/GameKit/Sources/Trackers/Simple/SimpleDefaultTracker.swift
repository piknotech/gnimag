//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// SimpleDefaultTracker is an abstract class providing useful default implementations for SimpleTrackerProtocol.
/// In particular, when inheriting from SimpleTracker, you can (and must) only customize the regression calculation method; all other methods are implemented for you.
open /*abstract*/ class SimpleDefaultTracker<F: Function>: SimpleTrackerProtocol {
    /// The time-value pairs.
    public private(set) var times = [Time]()
    public private(set) var values = [Value]()

    /// Time set ignoring duplicate time entries.
    private var distinctTimes = Set<Double>()

    /// Data-point-related characteristics of the tracker.
    public let maxDataPoints: Int
    public let requiredPointsForCalculatingRegression: Int

    /// The tolerance value which is used for validity checks.
    public var tolerance: TrackerTolerance

    /// Defaut initializer.
    public init(maxDataPoints: Int, requiredPointsForCalculatingRegression: Int, tolerance: TrackerTolerance) {
        self.maxDataPoints = maxDataPoints
        self.requiredPointsForCalculatingRegression = requiredPointsForCalculatingRegression
        self.tolerance = tolerance
    }

    /// The current regression function. Can be nil when, for example, the number of data points is insufficient.
    public private(set) var regression: F?

    // MARK: Method Implementations
    /// Add a data point to the tracker. Update the regression function with the new data point, if desired.
    public final func add(value: Value, at time: Time, updateRegression: Bool = true) {
        times.append(time)
        distinctTimes.insert(time)
        values.append(value)

        // Check maximum number of data points
        if times.count > maxDataPoints {
            let first = times.removeFirst()
            distinctTimes.remove(first)
            values.removeFirst()
        }

        if updateRegression {
            self.updateRegression()
        }
    }

    /// Explicitly update the regression function.
    public final func updateRegression() {
        if distinctTimes.count >= requiredPointsForCalculatingRegression {
            regression = calculateRegression()
        } else {
            regression = nil
        }
    }

    /// Clear all data points and discard the current regression function.
    public final func reset() {
        times.removeAll()
        distinctTimes.removeAll()
        values.removeAll()
        updateRegression()
    }

    /// Remove the last data point of the tracker. Update the regression function.
    /// Assumes there is at least one data point.
    public final func removeLast() {
        let last = times.removeLast()
        distinctTimes.remove(last)
        values.removeLast()
        updateRegression()
    }

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback. The default value for `fallback` is `.valid`.
    public func isDataPointValid(value: Value, time: Time, fallback: TrackerFallbackMethod = .valid) -> Bool {
        var expectedValue: Value!

        // Calculate expected value either from regression or from specified fallback
        if let regression = regression {
            expectedValue = regression.at(time)
        } else {
            switch fallback {
                case .valid: return true
                case .invalid: return false
                case .useLastValue: expectedValue = values.last! // Crash when no last value available
            }
        }

        // Calculate allowed difference
        var allowedDifference: Value
        switch tolerance {
            case let .absolute(maxDiff): allowedDifference = maxDiff
            case let .relative(tolerance): allowedDifference = abs(expectedValue) * tolerance
        }

        let difference = abs(value - expectedValue)
        return difference <= allowedDifference
    }

    /// Perform a validity check, but with a different tolerance value.
    /// This does not affect `self.tolerance`.
    public func isDataPoint(value: Value, time: Time, validWithTolerance tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid) -> Bool {
        let previous = self.tolerance
        self.tolerance = tolerance
        defer { self.tolerance = previous }

        return isDataPointValid(value: value, time: time, fallback: fallback)
    }

    // MARK: Abstract Methods
    /// Override this to calculate the regression for the current time/value-pairs.
    /// This method is only called if the number of data points is at least `requiredPointsForCalculatingRegression`.
    open func calculateRegression() -> F? {
        fatalError("This is an abstract method.")
    }
}
