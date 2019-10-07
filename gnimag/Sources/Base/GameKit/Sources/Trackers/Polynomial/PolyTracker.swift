//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

/// PolyTracker is a simple tracker providing a polynomial regression function
public class PolyTracker: SimpleDefaultTracker {
    /// Default initializer.
    public init(maxDataPoints: Int = 500, degree: Int, tolerancePoints: Int = 1) {
        self.degree = degree
        super.init(maxDataPoints: maxDataPoints, requiredPointsForCalculatingRegression: degree + tolerancePoints + 1)
    }

    /// The degree of the polynomial regression.
    private let degree: Int
    
    /// The current regression function as a Polynomial.
    public var polynomial: Polynomial? {
        regression as? Polynomial
    }

    /// Calculate the polynomial regression.
    open override func calculateRegression() -> SmoothFunction? {
        Regression.polyRegression(x: times, y: values, n: degree)
    }
}
