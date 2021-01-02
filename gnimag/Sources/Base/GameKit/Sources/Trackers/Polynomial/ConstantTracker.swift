//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Surge

/// ConstantTracker is a PolyTracker providing simple access to the calculated average value.
/// Because data points only consist of values here (time is irrelevant), ConstantTracker provides respective convenience methods.
public class ConstantTracker: PolyTracker {
    /// The number of values that have already been added.
    public private(set) var count: Double = 0

    /// Default initializer.
    public init(maxDataPoints: Int = 50, tolerancePoints: Int = 1, tolerance: TrackerTolerance = .absolute(0)) {
        super.init(maxDataPoints: maxDataPoints, degree: 0, tolerancePoints: tolerancePoints, tolerance: tolerance)
    }

    /// Convenience method to check for validity, ignoring the time component.
    public func isValueValid(_ value: Value, fallback: TrackerFallbackMethod = .valid) -> Bool {
        isDataPointValid(value: value, time: count, fallback: fallback)
    }

    /// Convenience method to check for validity, with a given tolerance, ignoring the time component.
    public func isValue(_ value: Value, validWithTolerance tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid) -> Bool {
        isDataPoint(value: value, time: count, validWithTolerance: tolerance, fallback: fallback)
    }

    /// Convenience method, ignoring the time component.
    public func add(value: Value, updateRegression: Bool = true) {
        add(value: value, at: count, updateRegression: updateRegression)
        count += 1
    }
    
    /// The average value, which is the result of the regression.
    /// Nil if not enough data points are available.
    public var average: Value? {
        regression?.a
    }

    /// The variance of the data points.
    public override var variance: Value? {
        average.map { Surge.variance(values, mean: $0) }
    }
}
