//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

/// PolyTracker is a simple tracker providing a polynomial regression function.
public class PolyTracker: SimpleDefaultTracker<Polynomial> {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, degree: Int, tolerancePoints: Int = 1, tolerance: TrackerTolerance) {
        self.degree = degree
        super.init(maxDataPoints: maxDataPoints, requiredPointsForCalculatingRegression: degree + tolerancePoints + 1, tolerance: tolerance)
    }

    /// The degree of the polynomial regression.
    private let degree: Int

    /// Calculate the polynomial regression.
    open override func calculateRegression() -> Polynomial? {
        Regression.polyRegression(x: times, y: values, n: degree)
    }

    /// Provide a specific ScatterStrokable for a polynomial.
    open override func scatterStrokable(for function: F) -> ScatterStrokable {
        switch function.degree {
        case 0, 1:
            return LinearScatterStrokable(line: function, drawingRange: .open)

        case 2:
            return QuadCurveScatterStrokable(parabola: function, drawingRange: .open)

        default:
            return ArbitraryFunctionScatterStrokable(function: function, drawingRange: .open, interpolationPoints: 50)
        }
    }
}
