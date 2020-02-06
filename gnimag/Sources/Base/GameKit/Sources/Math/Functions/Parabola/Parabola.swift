//
//  Created by David Knothe on 06.02.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A polynomial of degree 2, defined by the equation f(x) = ax^2 + bx + c.
public struct Parabola: DifferentiableFunction {
    /// The coefficients of the parabola, defined by f(x) = ax^2 + bx + c.
    public let a: Double
    public let b: Double
    public let c: Double

    /// Default initializer.
    @_transparent
    public init(a: Double, b: Double, c: Double) {
        self.a = a
        self.b = b
        self.c = c
    }

    /// Calculate the value at a given point.
    @_transparent
    public func at(_ x: Self.Value) -> Self.Value {
        a * x * x + b * x + c
    }

    /// The derivative of the parabola.
    @_transparent
    public var derivative: Function {
        LinearFunction(slope: 2 * a, intercept: b)
    }
}

// MARK: CustomStringConvertible
extension Parabola: CustomStringConvertible {
    /// Describe the parabola.
    public var description: String {
        // Round coefficients and construct string
        String(format: "%.3fx^2 + %.3fx + %.3f", a, b, c)
    }
}

// MARK: Arithmetic
extension Parabola: ScalarFunctionArithmetic {
    @_transparent
    public static func + (f: Parabola, offset: Double) -> Parabola {
        Parabola(a: f.a, b: f.b, c: f.c + offset)
    }

    @_transparent
    public static func - (f: Parabola, offset: Double) -> Parabola {
        f + (-offset)
    }

    @_transparent
    public static func * (f: Parabola, factor: Double) -> Parabola {
        Parabola(a: f.a * factor, b: f.b * factor, c: f.c * factor)
    }

    @_transparent
    public static func + (lhs: Parabola, rhs: Parabola) -> Parabola {
        Parabola(a: lhs.a + rhs.a, b: lhs.b + rhs.b, c: lhs.c + rhs.c)
    }

    @_transparent
    public static func - (lhs: Parabola, rhs: Parabola) -> Parabola {
        lhs + (-rhs)
    }

    @_transparent
    public static prefix func - (p: Parabola) -> Parabola {
        Parabola(a: -p.a, b: -p.b, c: -p.c)
    }

    @_transparent
    public func shiftedLeft(by amount: Double) -> Parabola {
        // Solve f(0) = self(amount), f'(0) = self'(amount); a stays same
        let b = derivative.at(amount) // b = f'(0) = self'(amount)
        let c = at(amount) // c = f(0) = self(amount)
        return Parabola(a: a, b: b, c: c)
    }
}
