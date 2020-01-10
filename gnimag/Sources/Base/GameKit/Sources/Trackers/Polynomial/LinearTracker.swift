//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// LinearTracker is a PolyTracker providing simple access to the calculated linear function.
public final class LinearTracker: SimpleDefaultTracker<LinearFunction> {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, tolerancePoints: Int = 1, tolerance: TrackerTolerance) {
        super.init(maxDataPoints: maxDataPoints, requiredPointsForCalculatingRegression: tolerancePoints + 2, tolerance: tolerance)
    }

    /// The slope of the linear regression function.
    /// Nil if not enough data points are available.
    public var slope: Value? {
        regression?.slope
    }

    /// The intercept of the linear regression function.
    /// Nil if not enough data points are available.
    public var intercept: Value? {
        regression?.intercept
    }

    /// Calculate the linear regression.
    public override func calculateRegression() -> LinearFunction? {
        Regression.linearRegression(x: times, y: values)
    }

    /// Provide a specific ScatterStrokable for a polynomial.
    public override func scatterStrokable(for function: LinearFunction) -> ScatterStrokable {
        return LinearScatterStrokable(line: function, drawingRange: .open)
    }
}
