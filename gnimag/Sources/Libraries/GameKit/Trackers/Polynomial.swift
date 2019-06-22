//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Polynomial describes a collection of coefficients representing a polynomial.

public final class Polynomial<Value> {
    /// The coefficients, beginning with the lowest one (x^0, x^1, ... x^n).
    public let coefficients: [Value]
    
    /// The degree of the polynomial.
    public var degree: Int {
        return coefficients.count - 1
    }

    /// Default initializer.
    /// Coefficients must not be empty.
    public init(_ coefficients: [Value]) {
        self.coefficients = coefficients
    }
    
    // MARK: Convenience coefficients
    // When you know the degree of the polynomial, use these coefficients.
    
    public var a: Value { return coefficients[degree - 0] }
    public var b: Value { return coefficients[degree - 1] }
    public var c: Value { return coefficients[degree - 2] }
    public var d: Value { return coefficients[degree - 3] }
    public var e: Value { return coefficients[degree - 4] }
}

// MARK: - Calculation

extension Polynomial where Value == Double {
    /// Calculate the value at a given point.
    public func f(_ x: Value) -> Value {
        var result = Value(0)
        
        for i in stride(from: degree, through: 0, by: -1) {
            result *= x
            result += coefficients[i]
        }
        
        return result
    }
    
    /// The derivative of the polynomial.
    public var derivative: Polynomial {
        // Trivial case
        if degree < 1 {
            return Polynomial([])
        }
        
        // Calculate new coefficients
        var deriv = coefficients.enumerated().map {
            Value($0.offset) * $0.element
        }
        deriv.removeFirst()
        
        return Polynomial(deriv)
    }
}

// MARK: - CustomStringConvertible

extension Polynomial: CustomStringConvertible {
    /// Describe the polynomial.
    public var description: String {
        // Trivial case
        if degree < 0 {
            return ""
        }
        
        var result = ""
        
        // Round coefficients
        let coeffs = coefficients.map { (a) -> String in
            let a = String(format: "%.3f", a as! CVarArg)
            return a
        }
        
        // Create description, using each coefficient
        if degree >= 2 {
            for i in stride(from: degree, through: 2, by: -1) {
                result += "\(coeffs[i])x^\(i) + "
            }
        }
        
        // Extra cases
        if degree >= 1 {
            result += "\(coeffs[1])x + "
        }
        
        result += "\(coeffs[0])"
        
        return result
    }
}
