//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

// An operator which allows writing shorthand-return-nil statements, combined with logging the failure reason, as follows:
// return nil & debug.failure = ..., or
// return nil & {debug.failure = ...}

infix operator & : NilDebugPrecedence
precedencegroup NilDebugPrecedence {
    lowerThan: AssignmentPrecedence
}

public func &<T>(lhs: T?, rhs: () -> Void) -> T? {
    rhs()
    return lhs
}

public func &<T>(lhs: T?, rhs: @autoclosure () -> Void) -> T? {
    rhs()
    return lhs
}

public func &<T>(lhs: T, rhs: () -> Void) -> T {
    rhs()
    return lhs
}

public func &<T>(lhs: T, rhs: @autoclosure () -> Void) -> T {
    rhs()
    return lhs
}

// An operator which allows printing anything (not necessarily CustomStringConvertible) and providing a default value, as follows:
// a = "Result: \(result ??? "NOT FOUND")"

infix operator ???
public func ???<T>(lhs: T?, rhs: String) -> String {
    lhs.map(anyDescription(of:)) ?? rhs
}

/// Return the description that will be printed wenn calling "print(any)". For example, for structs, this prints out all properties of the struct.
/// This allows printing things that are not necessarily CustomStringConvertible.
public func anyDescription(of any: Any) -> String {
    var result = ""
    print(any, terminator: "", to: &result)
    return result
}
