//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// Describes a function whose domain and codomain are both the real numbers (represented by `Double`).
public protocol Function {
    typealias Value = Double
    
    /// Calculate the value at a given point.
    func at(_ x: Value) -> Value
}

/// A Function type which conforms to ScalarFunctionArithmetic provides additional arithmetic functionality like scalar multiplication and addition.
public protocol ScalarFunctionArithmetic: Function {
    static func +(f: Self, offset: Double) -> Self
    static func *(f: Self, factor: Double) -> Self

    func shiftedLeft(by amount: Double) -> Self
}

/// DifferentiableFunctions provide a derivative function.
public protocol DifferentiableFunction: Function {
    var derivative: Function { get }
}
