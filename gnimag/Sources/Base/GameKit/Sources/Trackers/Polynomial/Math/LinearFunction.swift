//
//  Created by David Knothe on 10.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A linear function, which is defined by its slope and intercept.
/// A special case of a polynomial.
public struct LinearFunction: Function {
    public let slope: Value
    public let intercept: Value

    /// Default initializer.
    public init(slope: Value, intercept: Value) {
        self.slope = slope
        self.intercept = intercept
    }

    /// Calculate the value at a given point.
    public func at(_ x: Self.Value) -> Self.Value {
        slope * x + intercept
    }

    /// The inverse LinearFunction.
    public var inverse: LinearFunction {
        LinearFunction(slope: 1 / slope, intercept: -intercept / slope)
    }

}

// MARK: ScalarFunctionArithmetic
extension LinearFunction: ScalarFunctionArithmetic {
    public static func +(f: LinearFunction, offset: Double) -> LinearFunction {
        LinearFunction(slope: f.slope, intercept: f.intercept + offset)
    }

    public static func *(f: LinearFunction, factor: Double) -> LinearFunction {
        LinearFunction(slope: f.slope * factor, intercept: f.intercept * factor)
    }

    public func shiftedLeft(by amount: Double) -> LinearFunction {
        LinearFunction(slope: slope, intercept: intercept + slope * amount)
    }
}

// MARK: DifferentiableFunction
extension LinearFunction: DifferentiableFunction {
    public var derivative: Function {
        LinearFunction(slope: 0, intercept: slope)
    }
}

// MARK: More Arithmetic

/// Negate a LinearFunction.
public prefix func - (f: LinearFunction) -> LinearFunction {
    LinearFunction(slope: -f.slope, intercept: -f.intercept)
}

/// Add two LinearFunctions.
public func + (lhs: LinearFunction, rhs: LinearFunction) -> LinearFunction {
    LinearFunction(slope: lhs.slope + rhs.slope, intercept: lhs.intercept + rhs.intercept)
}

/// Subtract two LinearFunctions.
public func - (lhs: LinearFunction, rhs: LinearFunction) -> LinearFunction {
    lhs + (-rhs)
}
