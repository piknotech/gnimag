//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// A simple tracker tracks the course of a one-dimensional data variable over time. Once it has enough data points, it can map this data to a specific regression function.
/// "Simple" means that these trackers track ONE simple, closed-form, (probably continuous) mathematical function like sin, exp, or a polynomial. Trackers which consist of multiple compound functions are not desired here – see CompositeTracker.
public protocol SimpleTrackerProtocol: HasScatterDataSet {
    typealias Time = Double
    typealias Value = Double

    /// The specific function type of the regression which is produced by this tracker.
    associatedtype F: Function & ScalarFunctionArithmetic

    // MARK: Methods and Properties

    /// The tolerance value which is used for validity checks.
    var tolerance: TrackerTolerance { get set }

    /// The time-value pairs.
    var times: [Time] { get }
    var values: [Value] { get }

    /// After `maxDataPoints` have been added to the tracker, oldest values should be removed to keep the number of data points at `maxDataPoints`.
    var maxDataPoints: Int { get }

    /// This is a required, but not necessarily sufficient condition in order for a regression to exist.
    var requiredPointsForCalculatingRegression: Int { get }

    /// The current regression function. Can be nil when, for example, the number of data points is insufficient.
    var regression: F? { get }

    /// The variance of the data points.
    var variance: Value? { get }

    /// Add a data point to the tracker. Update the regression function with the new data point, if desired.
    func add(value: Value, at time: Time, updateRegression: Bool)

    /// Explicitly update the regression function.
    func updateRegression()

    /// Clear all data points and discard the current regression function.
    func reset()

    /// Remove the last data point of the tracker. Update the regression function.
    /// Assumes there is at least one data point.
    func removeLast()

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback. The default value for `fallback` should be `.valid`.
    func isDataPointValid(value: Value, time: Time, fallback: TrackerFallbackMethod) -> Bool

    /// Perform a validity check, but with a different tolerance value.
    /// This should not affect `self.tolerance`.
    func isDataPoint(value: Value, time: Time, validWithTolerance tolerance: TrackerTolerance, fallback: TrackerFallbackMethod) -> Bool

    /// Return a ScatterStrokable which matches the function. For debugging.
    func scatterStrokable(for function: F) -> ScatterStrokable

    /// Return a ScatterStrokable which describes the valid tolerance range around the given point, respective to the current tolerance and the given regression function. For debugging.
    func scatterStrokable(forToleranceRangeAroundTime: Time, value: Value, f: F) -> ScatterStrokable
}

public extension SimpleTrackerProtocol {
    /// Equivalent to `regression != nil`.
    var hasRegression: Bool {
        regression != nil
    }
}

// MARK: HasScatterDataSet

public extension SimpleTrackerProtocol {
    /// Return the raw data from the tracker.
    var dataSet: [ScatterDataPoint] {
        zip(times, values).map(ScatterDataPoint.init(x:y:))
    }
}

// MARK: Subtypes
// Swift doesn't allow protocols to have nested types.

public enum TrackerTolerance {
    /// Look at the difference between the expected value and the average value.
    /// Iff it is smaller than or equal to tolerance, return true.
    case absolute(SimpleTrackerProtocol.Value)

    /// Instead of just allowing a deviation in y direction, we also allow a deviation in x (time) direction.
    /// We draw an ellipse with radii (dx, dy) around the data point and see if it intersects the regression graph.
    /// This means, allowed deviations are: (dx, 0), (0, dy), (0.7*dx, 0.7*dy), ...
    /// Attention: dx should be comparatively small enough, and must be positive.
    case absolute2D(dy: SimpleTrackerProtocol.Value, dx: SimpleTrackerProtocol.Time)

    /// Look at the difference between the expected value and the average value.
    /// Iff it is smaller than or equal to (tolerance * expectedValue), return true.
    case relative(SimpleTrackerProtocol.Value)
}

public enum TrackerFallbackMethod {
    /// Return true when no regression is available.
    /// The default value.
    case valid

    /// Return false when no regression is available.
    case invalid

    /// Use the last added value when no regression is available.
    /// When there is no last added value, crash.
    case useLastValue
}
