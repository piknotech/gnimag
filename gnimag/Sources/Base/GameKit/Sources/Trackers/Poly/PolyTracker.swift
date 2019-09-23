//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

/// PolyTracker tracks the course of a one-dimensional data variable over time. Once it has enough data points, it maps this course to a specific polynomial regression function. Then, irregular points can be filtered out, and future values can be predicted.
public class PolyTracker: Tracker {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, degree: Int, tolerancePoints: Int = 1) {
        self.maxDataPoints = maxDataPoints
        self.degree = degree
        self.tolerancePoints = tolerancePoints
    }
    
    /// The data points, split into times and values. These are always the same size.
    fileprivate var times = [Time]()
    fileprivate var values = [Value]()

    /// Expose the latest added value.
    var lastValue: Value? { values.last }
    
    /// The maximum number of data points; when this amount is reached, earliest data points are discarded.
    private let maxDataPoints: Int

    /// The number of points that are required additionally before the first regression polynomial is calculated.
    /// So, instead of n+1 points (where n is the degree), n+1+tolerancePoints are required.
    private let tolerancePoints: Int
    
    /// The degree of the polynomial regression.
    private let degree: Int
    
    /// The current regression function, if available.
    public private(set) var regression: Polynomial<Value>?

    /// States if a regression function is available.
    public var hasRegression: Bool {
        regression != nil
    }

    // MARK: - Methods

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback.
    override public func `is`(_ value: Value, at time: Time, validWith tolerance: Tolerance, fallbackWhenNoRegression: FallbackMethod = .valid) -> Bool {
        var expectedValue: Value!

        // Calculate expected value either from regression or from specified fallback
        if let regression = regression {
            expectedValue = regression.at(time)
        } else {
            switch fallbackWhenNoRegression {
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

    /// Clear all data points and discard the current regression function.
    /// Use it e.g. when recent data points do not match the regression function anymore.
    public func clear() {
        times.removeAll()
        values.removeAll()
        updateRegression()
    }
    
    /// Add a data point to the tracker. Update the regression function with the new data point.
    public func add(value: Value, at time: Time) {
        times.append(time)
        values.append(value)
        
        // Check maximum number of data points
        if times.count > maxDataPoints {
            times.removeFirst()
            values.removeFirst()
        }
        
        updateRegression()
    }
    
    /// Remove the last data point of the tracker. Update the regression function.
    /// Assumes there is at least one data point.
    public func removeLast() {
        times.removeLast()
        values.removeLast()
        updateRegression()
    }

    /// Update the regression function.
    /// If not enough data points are available, the regression is set to nil.
    private func updateRegression() {
        let uniqueTimes = uniqueNumberOfElements(in: times, absoluteTolerance: 1/10_000)
        if uniqueTimes > degree + tolerancePoints { // Ignores duplicate entries for the same time
            regression = Regression.polyRegression(x: times, y: values, n: degree)
        } else {
            regression = nil
        }
    }
}

// MARK: Has2DDataSet (for MacTestingTools)
extension PolyTracker: Has2DDataSet {
    /// Return the current raw data from the tracker.
    public func yieldDataSet() -> (xValues: [Double], yValues: [Double]) {
        return (times, values)
    }
}

/// Count the unique number of elements in a set of doubles using a given tolerance for double comparison.
/// When two values are apart by more than the tolerance, but could be reached by a valid tolerance-path through other values (e.g. 0, tolerance, 2*tolerance), the result depends on the order of elements in the set.
private func uniqueNumberOfElements(in set: [Double], absoluteTolerance: Double) -> Int {
    var set = set
    var result = 0

    while let first = set.first {
        set.removeAll { $0.isAlmostEqual(to: first, tolerance: absoluteTolerance) }
        result += 1
    }

    return result
}
