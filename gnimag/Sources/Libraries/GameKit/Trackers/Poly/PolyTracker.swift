//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// PolyTracker tracks the course of a one-dimensional data variable over time. Once it has enough data points, it maps this course to a specific polynomial regression function. Then, irregular points can be filtered out, and future values can be predicted.

public class PolyTracker {
    public typealias Value = Double
    public typealias Time = Double
    
    /// Default initializer.
    public init(maxDataPoints: Int = .max, degree: Int, tolerancePoints: Int = 1) {
        self.maxDataPoints = maxDataPoints
        self.degree = degree
        self.tolerancePoints = tolerancePoints
    }
    
    /// The data points, split into times and values.
    private var times = [Time]()
    private var values = [Value]()
    
    /// The maximum number of data points; when this amount is reached, earliest data points are discarded.
    private let maxDataPoints: Int

    /// The number of points that are required additionally before the first regression polynomial is calculated.
    /// So, instead of n+1 points (where n is the degree), n+1+tolerancePoints are required.
    private let tolerancePoints: Int
    
    /// The degree of the polynomial regression.
    private let degree: Int
    
    /// The current regression function, if available.
    public private(set) var regression: Polynomial<Value>?

    // MARK: - Methods

    /// States if a given data point would be valid inside the current regression function, given an absolute tolerance value.
    /// Assumes that a regression function is available.
    public func isValue(_ value: Value, at time: Time, validWithTolerance tolerance: Value) -> Bool {
        return abs(regression!.f(time) - value) <= tolerance
    }
    
    /// Clear all data points and discard the current regression function.
    /// Use it e.g. when recent data points do not match the regression function anymore.
    public func clear() {
        times.removeAll()
        values.removeAll()
        regression = nil
    }
    
    /// Add a data point to the tracker. Update the regression function with the new data point.
    public func add(value: Value, at time: Time) {
        times.append(time)
        values.append(value)
        
        // Check number of data points
        if times.count > maxDataPoints {
            times.removeFirst()
            values.removeFirst()
        }
        
        // Calculate regression
        if times.count > degree + tolerancePoints {
            regression = Regression.polyRegression(x: times, y: values, n: degree)
        }
    }
    
    /// Remove the last data point of the tracker. Update the regression function.
    /// Assumes there is at least one data point.
    public func removeLast() {
        times.removeLast()
        values.removeLast()
        
        // Calculate regression
        if times.count > degree {
            regression = Regression.polyRegression(x: times, y: values, n: degree)
        }
    }
    
    /// TODO: Remove
    /// Print the values of the tracker as a dictionary. Use for debugging.
    public func print() {
        var dict = [Time: Value]()
        for (time, value) in zip(times, values) {
            dict[time] = value
        }
        Swift.print(dict)
    }
}
