//
//  Created by David Knothe on 23.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// A simple helper class to disguise arbitrary functions as trackers to be able to call `isDataPointValid` with a given tolerance.
internal class AnyFunctionToleranceChecker<F: Function & ScalarFunctionArithmetic>: SimpleDefaultTracker<F> {
    private let function: F

    /// Default initializer.
    init(function: F, tolerance: TrackerTolerance) {
        self.function = function
        super.init(maxDataPoints: 0, requiredPointsForCalculatingRegression: 0, tolerance: tolerance)
        updateRegression() // Immediately update the regression with the given function
    }

    /// Provide the static function as regression function.
    override func calculateRegression() -> F? {
        function
    }
}
