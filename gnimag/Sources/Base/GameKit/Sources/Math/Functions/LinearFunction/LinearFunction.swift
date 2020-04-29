//
//  Created by David Knothe on 10.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A linear function, which is defined by its slope and intercept.
public struct LinearFunction: Function {
    public let slope: Value
    public let intercept: Value

    /// Default initializer.
    @_transparent
    public init(slope: Value, intercept: Value) {
        self.slope = slope
        self.intercept = intercept
    }

    /// Create a LinearFunction going through two points.
    /// The x values must be different.
    @_transparent
    public init(through point1: (x: Value, y: Value), and point2: (x: Value, y: Value)) {
        slope = (point1.y - point2.y) / (point1.x - point2.x)
        intercept = point1.y - slope * point1.x
    }

    /// Calculate the value at a given point.
    @_transparent
    public func at(_ x: Self.Value) -> Self.Value {
        slope * x + intercept
    }

    /// The inverse LinearFunction, such that `self(inverse(x)) = inverse(self(x)) = x`.
    @_transparent
    public var inverse: LinearFunction {
        LinearFunction(slope: 1 / slope, intercept: -intercept / slope)
    }
}

// MARK: ScalarFunctionArithmetic
extension LinearFunction: ScalarFunctionArithmetic {
    @_transparent
    public static func +(f: LinearFunction, offset: Double) -> LinearFunction {
        LinearFunction(slope: f.slope, intercept: f.intercept + offset)
    }

    @_transparent
    public static func -(f: LinearFunction, offset: Double) -> LinearFunction {
        LinearFunction(slope: f.slope, intercept: f.intercept - offset)
    }

    @_transparent
    public static func *(f: LinearFunction, factor: Double) -> LinearFunction {
        LinearFunction(slope: f.slope * factor, intercept: f.intercept * factor)
    }

    @_transparent
    public func shiftedLeft(by amount: Double) -> LinearFunction {
        LinearFunction(slope: slope, intercept: intercept + slope * amount)
    }
}

// MARK: DifferentiableFunction
extension LinearFunction: DifferentiableFunction {
    @_transparent
    public var derivative: Function {
        LinearFunction(slope: 0, intercept: slope)
    }

    /// The derivative at a single value.
    @_transparent
    public func derivative(at value: Value) -> Value {
        slope
    }
}

// MARK: More Arithmetic

/// Negate a LinearFunction.
@_transparent
public prefix func - (f: LinearFunction) -> LinearFunction {
    LinearFunction(slope: -f.slope, intercept: -f.intercept)
}

/// Add two LinearFunctions.
@_transparent
public func + (lhs: LinearFunction, rhs: LinearFunction) -> LinearFunction {
    LinearFunction(slope: lhs.slope + rhs.slope, intercept: lhs.intercept + rhs.intercept)
}

/// Subtract two LinearFunctions.
@_transparent
public func - (lhs: LinearFunction, rhs: LinearFunction) -> LinearFunction {
    lhs + (-rhs)
}
