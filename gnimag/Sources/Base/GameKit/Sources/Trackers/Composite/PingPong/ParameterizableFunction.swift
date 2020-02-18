//
//  Created by David Knothe on 26.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A Function type which conforms to ParameterizableFunction can be compressed into and read from an array of Double values.
/// This allows calculating a mean function of multiple functions by simply calculating the mean value for each parameter position.
public protocol ParameterizableFunction: Function {
    /// Return the parameter representation of the function.
    var coefficients: [Double] { get }

    /// Try constructing a function from the given parameter representation.
    init?(_ coefficients: [Double])
}
