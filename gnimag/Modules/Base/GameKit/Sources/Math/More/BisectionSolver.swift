//
//  Created by David Knothe on 21.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

public enum BisectionSolver {
    /// Find the intersection of the given functions inside the given range via bisection.
    /// `(f-g)(range.upper)` and `(f-g)(range.lower)` must have different signs, else, this method returns nil.
    public static func intersection(of f1: Function, and f2: Function, in range: SimpleRange<Double>, epsilon: Double = 1e-8) -> Double? {
        let diff = FunctionWrapper { f1.at($0) - f2.at($0) }
        return zero(of: diff, in: range, epsilon: epsilon)
    }

    /// Find the solution of the given equation inside the given range via bisection.
    /// `f(range.upper) - const` and `f(range.lower) - const` must have different signs; else, this method returns nil.
    public static func solve(_ f: Function, equals const: Double, in range: SimpleRange<Double>, epsilon: Double = 1e-8) -> Double? {
        let const = FunctionWrapper { _ in const }
        return intersection(of: f, and: const, in: range, epsilon: epsilon)
    }

    /// Find the zero of the given function inside the given range via bisection.
    /// `f(range.upper)` and `f(range.lower)` must have different signs; else, this method returns nil.
    public static func zero(of f: Function, in range: SimpleRange<Double>, epsilon: Double = 1e-8) -> Double? {
        if range.isEmpty { return nil }

        var min = range.lower
        var max = range.upper

        // Precondition
        let signAtMin = sign(f.at(min))
        if signAtMin == 0 { return min } // Found a solution
        if sign(f.at(max)) == signAtMin { return nil } // Signs are not different

        // Bisection loop
        while max - min > epsilon {
            let mid = (min + max) / 2
            let midSign = sign(f.at(mid))
            if midSign == 0 { return mid }

            if midSign == signAtMin {
                min = mid
            } else {
                max = mid
            }
        }

        return (min + max) / 2
    }
}
