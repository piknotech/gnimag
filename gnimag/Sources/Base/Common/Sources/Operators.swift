//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

infix operator ??=

/// Shorthand for lhs = lhs ?? rhs.
@_transparent
public func ??=<T>(lhs: inout Optional<T>, rhs: @autoclosure () -> Optional<T>) {
    lhs = lhs ?? rhs()
}


infix operator +/: AdditionPrecedence

/// Concatenate two path components.
/// This is better than ... + "/" + ... because it correctly deals with slashes on both sides.
public func +/(lhs: String, rhs: String) -> String {
    NSString.path(withComponents: [lhs, rhs])
}


postfix operator %

/// Use % to write tolerance values, e.g. 5%.
public postfix func %(a: Double) -> Double {
    return a * 0.01
}


/// Syntactic sugar for { $0 }.
@_transparent
public func id<T>(_ t: T) -> T {
    t
}
