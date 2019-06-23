//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// ConstantTracker is a PolyTracker providing simple access to the calculated average value.
/// Because data points only consist of values here (time is irrelevant), ConstantTracker provides respective convenience methods.

public final class ConstantTracker: PolyTracker {
    /// Default initializer.
    public init(maxDataPoints: Int = .max, tolerancePoints: Int = 0) {
        super.init(maxDataPoints: maxDataPoints, degree: 0, tolerancePoints: tolerancePoints)
    }
    
    /// Convenience method, ignoring the time component.
    public func value(_ value: Value, isValidWithTolerance tolerance: Value) -> Bool {
        return self.value(value, isValidWithTolerance: tolerance, at: 0)
    }
    
    /// Convenience method, ignoring the time component.
    public func add(value: Value) {
        add(value: value, at: 0)
    }
    
    /// The average value, which is the result of the regression.
    /// Nil if not enough data points are available.
    public var average: Value? {
        return regression?.a
    }
}
