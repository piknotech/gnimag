//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

public enum QuadraticSolver {
    /// Solve the equation given by ax^2 + bx + c = 0 and return both solutions.
    /// If there is only one solution, it is returned twice.
    public static func solve(a: Double, b: Double, c: Double) -> (Double, Double)? {
        // Special case: a == 0
        if a == 0 {
            if b == 0 { return nil }
            return (-c/b, -c/b)
        }

        // General case: use p/q-formula
        let p = b/a, q = c/a
        let discriminant = p*p/4 - q
        if discriminant < 0 { return nil }

        let d = sqrt(discriminant)
        return (-p/2 - d, -p/2 + d)
    }

    /// Solve the equation given by ax^2 + bx + c = 0; return the solution which is nearest to the given guess.
    public static func solve(a: Double, b: Double, c: Double, solutionNearestToGuess guess: Double) -> Double? {
        guard let (x1, x2) = solve(a: a, b: b, c: c) else { return nil }

        if abs(x1 - guess) < abs(x2 - guess) {
            return x1
        } else {
            return x2
        }
    }
}

public enum LinearSolver {
    /// Solve the equation given by slope * x + intercept = 0 and return the solution.
    public static func solve(slope: Double, intercept: Double) -> Double? {
        if slope == 0 { return nil }
        return -intercept / slope
    }
}
