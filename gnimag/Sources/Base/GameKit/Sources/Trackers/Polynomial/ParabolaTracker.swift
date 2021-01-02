//
//  Created by David Knothe on 06.02.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// ParabolaTracker is a simple tracker providing a parabola regression function.
public final class ParabolaTracker: SimpleDefaultTracker<Parabola> {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, tolerancePoints: Int = 1, tolerance: TrackerTolerance) {
        super.init(maxDataPoints: maxDataPoints, requiredPointsForCalculatingRegression: tolerancePoints + 3, tolerance: tolerance)
    }

    /// Calculate the linear regression.
    public override func calculateRegression() -> Parabola? {
        let poly = Regression.polyRegression(x: times, y: values, n: 2)
        return Parabola(a: poly.a, b: poly.b, c: poly.c)
    }

    /// Provide a specific ScatterStrokable for a polynomial.
    public override func scatterStrokable(for function: Parabola) -> ScatterStrokable {
        QuadCurveScatterStrokable(parabola: function, drawingRange: .open)
    }
}
