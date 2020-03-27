//
//  Created by David Knothe on 27.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A rational number is represented by a fraction, num / denom.
/// Thereby, the numerator is an integer, while the denominator is always nonnegative.
struct RationalNumber: Comparable, AdditiveArithmetic {
    let num: Int
    let denom: Int

    static var zero: Self {
        Self(num: 0, denom: 1)
    }

    /// A RationalNumber is invalid iff its denominator is zero (regardless of its numerator).
    var isInfinity: Bool {
        denom == 0
    }

    /// Default initializer.
    /// Reduces the fraction as far as possible. Also assures that the denominator is nonnegative.
    /// If denominator is zero, this number is marked as invalid.
    init(num: Int, denom: Int) {
        let gcd = max(1, Self.gcd(num, denom)) // Disallow 0
        let sign = denom.signum()

        self.num = num / gcd * sign
        self.denom = denom / gcd * sign
    }

    // MARK: Arithmetic

    /// Add two rational numbers.
    static func +(lhs: Self, rhs: Self) -> Self {
        if lhs.denom == rhs.denom {
            return Self(num: lhs.num + rhs.num, denom: lhs.denom)
        } else {
            let num = lhs.num * rhs.denom + lhs.denom * rhs.num
            return Self(num: num, denom: lhs.denom * rhs.denom)
        }
    }

    /// Subtract two rational numbers. Reduce the denominator as far as possible.
    static func -(lhs: Self, rhs: Self) -> Self {
        lhs + (-rhs)
    }

    /// Negate a rational number.
    static prefix func -(a: Self) -> Self {
        Self(num: -a.num, denom: a.denom)
    }

    /// Multiply two rational numbers.
    static func *(lhs: Self, rhs: Self) -> Self {
        Self(num: lhs.num * rhs.num, denom: lhs.denom * rhs.denom)
    }

    /// The multiplicative inverse of a rational number.
    /// The inverse of zero is an invalid rational number.
    var inverse: Self {
        Self(num: denom, denom: num)
    }

    /// Divide two rational numbers.
    static func /(lhs: Self, rhs: Self) -> Self {
        lhs * rhs.inverse
    }

    // MARK: Equality

    /// Compare two rational numbers.
    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.num * rhs.denom == lhs.denom * rhs.num
    }

    /// Compare two rational numbers.
    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.num * rhs.denom < lhs.denom * rhs.num
    }

    /// Compare two rational numbers.
    static func >(lhs: Self, rhs: Self) -> Bool {
        lhs.num * rhs.denom > lhs.denom * rhs.num
    }

    // MARK: GCD and LCM

    /// Calculate the greatest common divisor of two numbers. Thereby, gcd(0, x) = x.
    /// The result is always nonnegative.
    fileprivate static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = abs(a)
        var b = abs(b)
        while b != 0 {
            let t = b
            b = a % b
            a = t
        }
        return a
    }

    /// Calculate the least common multiple of two numbers. Thereby, gcd(0, x) = 0.
    private static func lcm(_ a: Int, _ b: Int) -> Int {
        (a * b) / gcd(a, b)
    }
}
