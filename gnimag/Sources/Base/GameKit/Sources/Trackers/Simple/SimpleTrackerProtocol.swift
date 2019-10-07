//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

/// A simple tracker tracks the course of a one-dimensional data variable over time. Once it has enough data points, it can map this data to a specific (smooth) regression function.
/// "Simple" means that these trackers track ONE simple, closed-form, smooth mathematical function like sin, exp, or a polynomial. Trackers which consist of multiple compound functions are not desired here – see CompositeTracker.
public protocol SimpleTrackerProtocol: Has2DDataSet {
    typealias Time = Double
    typealias Value = Double

    // MARK: Methods and Properties

    /// The time-value pairs.
    var times: [Time] { get }
    var values: [Value] { get }

    /// After `maxDataPoints` have been added to the tracker, oldest values should be removed to keep the number of data points at `maxDataPoints`.
    var maxDataPoints: Int { get }

    // This is a required, but not necessarily sufficient condition for a regression ot exist.
    var requiredPointsForCalculatingRegression: Int { get }

    /// The current regression function. Can be nil when, for example, the number of data points is insufficient.
    var regression: SmoothFunction? { get }

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
    /// If there is no regression, use the specified fallback.
    func `is`(_ value: Value, at time: Time, validWith tolerance: TrackerTolerance, fallbackWhenNoRegression: TrackerFallbackMethod) -> Bool
}

// MARK: Has2DDataSet
public extension SimpleTrackerProtocol {
    /// Conformance to Has2DDataSet.
    func yieldDataSet() -> (xValues: [Double], yValues: [Double]) {
        (values, times)
    }
}


// MARK: Subtypes
// Swift doesn't allow protocols to have nested types.

public enum TrackerTolerance {
    /// Look at the difference between the expected value and the average value.
    /// Iff it is smaller than or equal to tolerance, return true.
    case absolute(tolerance: SimpleTrackerProtocol.Value)

    /// Look at the difference between the expected value and the average value.
    /// Iff it is smaller than or equal to (tolerance * expectedValue), return true.
    case relative(tolerance: SimpleTrackerProtocol.Value)
}

public enum TrackerFallbackMethod {
    /// Return true when no regression is available.
    case valid

    /// Return false when no regression is available.
    case invalid

    /// Use the last added value when no regression is available.
    /// When there is no last added value, crash.
    case useLastValue
}
