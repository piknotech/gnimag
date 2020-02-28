//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import simd
import Surge
import TestingTools

/// SimpleDefaultTracker is an abstract class providing useful default implementations for SimpleTrackerProtocol.
/// In particular, when inheriting from SimpleTracker, you can (and must) only customize the regression calculation method; all other methods are implemented for you.
open /*abstract*/ class SimpleDefaultTracker<F: Function & ScalarFunctionArithmetic>: SimpleTrackerProtocol {
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

    /// Calculate the variance of the data points.
    open var variance: Value? {
        guard let regression = regression else { return nil }

        let expectedValues = times.map(regression.at(_:))
        let differences = sub(expectedValues, values) // X-λ
        return measq(differences)
    }

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback. The default value for `fallback` is `.valid`.
    public func isDataPointValid(value: Value, time: Time, fallback: TrackerFallbackMethod = .valid) -> Bool {
        // Fallback when no regression is available
        guard let f = regression else {
            switch fallback {
            case .valid: return true
            case .invalid: return false
            case .useLastValue: return validityCheckUsingLastValue(value: value, time: time)
            }
        }

        // Normal check using regression function
        switch tolerance {
        case let .absolute(tolerance):
            return abs(f.at(time) - value) <= tolerance

        case let .relative(tolerance):
            return abs(f.at(time) - value) <= abs(f.at(time)) * tolerance

        case let .absolute2D(dy: dy, dx: dx):
            return validityCheckWithCircularTolerance(value: value, time: time, dx: dx, dy: dy, f: f)
        }
    }

    /// The validity check just using the last value.
    private func validityCheckUsingLastValue(value: Value, time: Time) -> Bool {
        let y = values.last!

        switch tolerance {
        case let .absolute(tolerance):
            return abs(y - value) <= tolerance

        case let .absolute2D(dy: dy, dx: _):
            return abs(y - value) <= dy

        case let .relative(tolerance):
            return abs(y - value) <= y * tolerance
        }
    }

    /// The validity check for a tolerance of `.absolute2D(dy: dy, dx: dx)`.
    private func validityCheckWithCircularTolerance(value: Value, time: Time, dx: Value, dy: Time, f: F) -> Bool {
        // 1.: Direct check
        if abs(f.at(time) - value) <= dy { return true }

        // 2.: Check sign of values at (x-dx, x+dx) and compare with value at x
        // ATTENTION: This assumes that f is continuous and defined everywhere (i.e. on R).
        let m = f.at(time) - value
        let l = f.at(time - dx) - value
        let r = f.at(time + dx) - value
        if sign(m) != sign(l) || sign(m) != sign(r) || sign(l) != sign(r) {
            return true
        }

        // 3.: Perform check at some values in (x-dx, x+dx). Start with the direction where the slope at x is pointing to.
        // A slope > 0 means: start looking to the left
        let deriv = (f as? DifferentiableFunction)?.derivative.at(time) ?? abs(r) - abs(l)
        let by = dx / 5
        let left = Array(stride(from: time - dx + by, to: time, by: by))
        let right = Array(stride(from: time + by, to: time + dx, by: by))

        for x in deriv > 0 ? (left + right) : (right + left) {
            let ydiff = abs(f.at(x) - value)
            let xdiff = abs(x - time)
            if pow(xdiff / dx, 2) + pow(ydiff / dy, 2) <= 1 { return true }
        }

        return false
    }

    /// Perform a validity check, but with a different tolerance value.
    /// This does not affect `self.tolerance`.
    public func isDataPoint(value: Value, time: Time, validWithTolerance tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid) -> Bool {
        let previous = self.tolerance
        self.tolerance = tolerance
        defer { self.tolerance = previous }

        return isDataPointValid(value: value, time: time, fallback: fallback)
    }

    /// Return a ScatterStrokable which describes the valid tolerance range around the given point, respective to the current tolerance and the given regression function. For debugging.
    public final func scatterStrokable(forToleranceRangeAroundTime time: Time, value: Value, f: F) -> ScatterStrokable {
        switch tolerance {
        case let .absolute(tolerance):
            return VerticalLineSegmentScatterStrokable(x: time, yCenter: value, yRadius: tolerance)

        case let .absolute2D(dy: dy, dx: dx):
            return EllipseScatterStrokable(center: (time, value), radii: (dx, dy))

        case let .relative(tolerance):
            let tolerance = tolerance * f.at(time) // Relative tolerance
            return VerticalLineSegmentScatterStrokable(x: time, yCenter: value, yRadius: tolerance)
        }
    }

    // MARK: Abstract Methods
    /// Override this to calculate the regression for the current time/value-pairs.
    /// This method is only called if the number of data points is at least `requiredPointsForCalculatingRegression`.
    open func calculateRegression() -> F? {
        fatalError("This is an abstract method.")
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    open func scatterStrokable(for function: F) -> ScatterStrokable {
        fatalError("This is an abstract method")
    }
}
