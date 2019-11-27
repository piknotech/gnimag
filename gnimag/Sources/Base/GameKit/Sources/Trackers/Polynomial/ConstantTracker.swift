//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// ConstantTracker is a PolyTracker providing simple access to the calculated average value.
/// Because data points only consist of values here (time is irrelevant), ConstantTracker provides respective convenience methods.
public final class ConstantTracker: PolyTracker {
    /// The number of values that have already been added.
    private var count: Double = 0

    /// Default initializer.
    public init(maxDataPoints: Int = 50, tolerancePoints: Int = 1, tolerance: TrackerTolerance) {
        super.init(maxDataPoints: maxDataPoints, degree: 0, tolerancePoints: tolerancePoints, tolerance: tolerance)
    }

    /// Convenience method to check for validity, ignoring the time component.
    public func isValueValid(_ value: Value, fallback: TrackerFallbackMethod = .valid) -> Bool {
        return isDataPointValid(value: value, time: .zero, fallback: fallback)
    }

    /// Convenience method, ignoring the time component.
    public func add(value: Value) {
        add(value: value, at: count)
        count += 1
    }
    
    /// The average value, which is the result of the regression.
    /// Nil if not enough data points are available.
    public var average: Value? {
        regression?.a
    }
}
