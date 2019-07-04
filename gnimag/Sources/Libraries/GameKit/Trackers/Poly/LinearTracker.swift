//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// LinearTracker is a PolyTracker providing simple access to the calculated linear function.

public final class LinearTracker: PolyTracker {
    /// Default initializer.
    public init(maxDataPoints: Int = .max, tolerancePoints: Int = 1) {
        super.init(maxDataPoints: maxDataPoints, degree: 1, tolerancePoints: tolerancePoints)
    }
    
    /// The slope of the linear regression function.
    /// Nil if not enough data points are available.
    public var slope: Value? {
        return regression?.a
    }
    
    /// The intercept of the linear regression function.
    /// Nil if not enough data points are available.
    public var intercept: Value? {
        return regression?.b
    }
}
