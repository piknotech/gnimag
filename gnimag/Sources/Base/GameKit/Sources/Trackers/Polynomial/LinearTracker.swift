//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// LinearTracker is a PolyTracker providing simple access to the calculated linear function.
public final class LinearTracker: PolyTracker {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, tolerancePoints: Int = 1, tolerance: TrackerTolerance) {
        super.init(maxDataPoints: maxDataPoints, degree: 1, tolerancePoints: tolerancePoints, tolerance: tolerance)
    }
    
    /// The slope of the linear regression function.
    /// Nil if not enough data points are available.
    public var slope: Value? {
        regression?.a
    }
    
    /// The intercept of the linear regression function.
    /// Nil if not enough data points are available.
    public var intercept: Value? {
        regression?.b
    }

    /// The slope and the intercept as a convenience tuple.
    public var slopeAndIntercept: (slope: Value, intercept: Value)? {
        if let slope = slope, let intercept = intercept {
            return (slope, intercept)
        } else {
            return nil
        }
    }
}
