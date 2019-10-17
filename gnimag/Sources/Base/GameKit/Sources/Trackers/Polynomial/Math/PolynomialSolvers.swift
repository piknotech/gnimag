//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

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
}
