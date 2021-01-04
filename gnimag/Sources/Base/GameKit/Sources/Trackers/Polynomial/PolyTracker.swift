//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// PolyTracker is a simple tracker providing a polynomial regression function.
public class PolyTracker: SimpleDefaultTracker<Polynomial> {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, degree: Int, tolerancePoints: Int = 1, tolerance: TrackerTolerance, maxDataPointsForLogging: Int? = nil) {
        self.degree = degree
        super.init(maxDataPoints: maxDataPoints, requiredPointsForCalculatingRegression: degree + tolerancePoints + 1, tolerance: tolerance, maxDataPointsForLogging: maxDataPointsForLogging)
    }

    /// The degree of the polynomial regression.
    private let degree: Int

    /// Calculate the polynomial regression.
    open override func calculateRegression() -> Polynomial? {
        Regression.polyRegression(x: times, y: values, n: degree)
    }

    /// Provide a specific ScatterStrokable for a polynomial.
    open override func scatterStrokable(for function: Polynomial) -> ScatterStrokable {
        switch function.degree {
        case 0, 1:
            let slope = function.at(1) - function.at(0), intercept = function.at(0)
            let line = LinearFunction(slope: slope, intercept: intercept)
            return LinearScatterStrokable(line: line, drawingRange: .open)

        case 2:
            let parabola = Parabola(a: function.a, b: function.b, c: function.c)
            return QuadCurveScatterStrokable(parabola: parabola, drawingRange: .open)

        default:
            return ArbitraryFunctionScatterStrokable(function: function, drawingRange: .open, interpolationPoints: 50)
        }
    }
}
