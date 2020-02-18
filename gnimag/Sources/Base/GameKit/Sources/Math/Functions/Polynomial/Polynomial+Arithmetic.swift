//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

// As Polynomials over R form a ring, this file contains necessary addition and multiplication methods, and more convenience arithmetic functions.

extension Polynomial: ParameterizableFunction {
}

extension Polynomial: ScalarFunctionArithmetic {
}

/// Perform polynomial addition.
@_transparent
public func + (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    let degree = max(lhs.degree, rhs.degree)

    // Extend missing coefficients of either left or right side (or none)
    let lhsCoefficients = lhs.coefficients + [Double](repeating: 0, count: degree - lhs.degree)
    let rhsCoefficients = rhs.coefficients + [Double](repeating: 0, count: degree - rhs.degree)

    return Polynomial(zip(lhsCoefficients, rhsCoefficients).map(+))
}

/// Perform polynomial subtraction.
@_transparent
public func - (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    lhs + (-rhs)
}

/// Perform polynomial multiplication.
/// This runs in O(n*m).
@_transparent
public func * (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    var result = [Double](repeating: 0, count: lhs.degree + rhs.degree + 1)

    // Multiply each coefficient of the left side with each coefficient of the right side
    for ((i, x), (j, y)) in Array(lhs.coefficients.enumerated()) × Array(rhs.coefficients.enumerated()) {
        result[i + j] += x * y
    }

    return Polynomial(result)
}

/// Add a constant to a polynomial.
@_transparent
public func + (lhs: Polynomial, rhs: Double) -> Polynomial {
    var new = lhs.coefficients
    new[0] += rhs
    return Polynomial(new)
}

/// Multiply a polynomial by a constant.
public func * (lhs: Double, rhs: Polynomial) -> Polynomial {
    Polynomial(rhs.coefficients.map { $0 * lhs })
}

/// Multiply a polynomial by a constant.
public func * (lhs: Polynomial, rhs: Double) -> Polynomial {
    rhs * lhs
}

/// Divide a polynomial by a constant.
public func / (lhs: Polynomial, rhs: Double) -> Polynomial {
    Polynomial(lhs.coefficients.map { $0 / rhs })
}

/// Negate a polynomial.
@_transparent
public prefix func - (p: Polynomial) -> Polynomial {
    Polynomial(p.coefficients.map(-))
}

extension Polynomial {
    /// Shift a polynomial to the left.
    /// This runs in O(n^2).
    @_transparent
    public func shiftedLeft(by amount: Double) -> Polynomial {
        var result = [Double](repeating: 0, count: coefficients.count)

        // Calculate (x-amount)^n
        for (n, coefficient) in coefficients.enumerated() {
            for k in 0 ... n { // x^k factor: x^k * amount^(n-k) * (n choose k)
                let power = pow(amount, Double(n-k)) * choose(n, k)
                result[k] += power * coefficient
            }
        }

        return Polynomial(result)
    }

    /// Calculate the binomial coefficient.
    @usableFromInline
    internal func choose(_ n: Int, _ k: Int) -> Double {
        var result: Double = 1

        for i in 0 ..< k {
            let factor = Double(n - i) / Double(i + 1)
            result *= factor
        }

        return result
    }
}

extension Polynomial {
    /// Stretch or compress the polynomial by the given factor in x-direction, around the given center point, so that the value at the center point doesn't change.
    /// A factor > 1 means that the polynomial will be stretched, i.e. widened out; factor must not be 0.
    /// This runs in O(n^2).
    public func stretched(by factor: Double, center: Double) -> Polynomial {
        let shifted = shiftedLeft(by: center)

        // Transform coefficients:
        // a * x^n --> a * (x/factor)^n = a/(factor)^n * x^n
        let coeffs = shifted.coefficients.enumerated().map { arg -> Double in
            let (i, coeff) = arg
            return coeff / pow(factor, Double(i))
        }

        let shiftedBack = Polynomial(coeffs).shiftedLeft(by: -center)

        return shiftedBack
    }
}
