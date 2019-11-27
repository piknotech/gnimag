//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

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
}
