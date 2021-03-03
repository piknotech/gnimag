//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

public enum QuadraticSolver {
    /// Solve the equation given by `parabola(x) = value` and return the solution which is nearest to the given guess.
    @_transparent
    public static func solve(_ parabola: Parabola, equals value: Double) -> (Double, Double)? {
        zero(of: parabola - value)
    }

    /// Solve the equation given by `parabola(x) = value` and return both solutions.
    /// If there is only one solution, it is returned twice.
    @_transparent
    public static func solve(_ parabola: Parabola, equals value: Double, solutionNearestToGuess guess: Double) -> Double? {
        zero(of: parabola - value, solutionNearestToGuess: guess)
    }

    /// Solve the equation given by `parabola(x) = 0` and return both solutions.
    /// If there is only one solution, it is returned twice.
    @_transparent
    public static func zero(of parabola: Parabola) -> (Double, Double)? {
        let a = parabola.a, b = parabola.b, c = parabola.c

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

    /// Solve the equation given by `parabola(x) = 0` and return the solution which is nearest to the given guess.
    @_transparent
    public static func zero(of parabola: Parabola, solutionNearestToGuess guess: Double) -> Double? {
        guard let (x1, x2) = zero(of: parabola) else { return nil }

        if abs(x1 - guess) < abs(x2 - guess) {
            return x1
        } else {
            return x2
        }
    }
}
