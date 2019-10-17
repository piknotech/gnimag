//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

// As Polynomials over R form a ring, this file contains the necessary addition and multiplication methods.

/// Perform polynomial addition.
public func + (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    let degree = max(lhs.degree, rhs.degree)

    // Extend missing coefficients of either left or right side (or none)
    let lhsCoefficients = lhs.coefficients + [Double](repeating: 0, count: degree - lhs.degree)
    let rhsCoefficients = rhs.coefficients + [Double](repeating: 0, count: degree - rhs.degree)

    return Polynomial(zip(lhsCoefficients, rhsCoefficients).map(+))
}

/// Perform polynomial subtraction.
public func - (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    lhs + (-rhs)
}

/// Perform polynomial multiplication.
/// This runs in O(n*m).
public func * (lhs: Polynomial, rhs: Polynomial) -> Polynomial {
    var result = [Double](repeating: 0, count: lhs.degree + rhs.degree + 1)

    // Multiply each coefficient of the left side with each coefficient of the right side
    for ((i, x), (j, y)) in Array(lhs.coefficients.enumerated()) × Array(rhs.coefficients.enumerated()) {
        result[i + j] += x * y
    }

    return Polynomial(result)
}

/// Multiply a polynomial by a constant.
public func * (lhs: Double, rhs: Polynomial) -> Polynomial {
    Polynomial(rhs.coefficients.map { $0 * lhs })
}

/// Divide a polynomial by a constant.
public func / (lhs: Polynomial, rhs: Double) -> Polynomial {
    Polynomial(lhs.coefficients.map { $0 / rhs })
}

/// Negate a polynomial.
public prefix func - (p: Polynomial) -> Polynomial {
    Polynomial(p.coefficients.map(-))
}
