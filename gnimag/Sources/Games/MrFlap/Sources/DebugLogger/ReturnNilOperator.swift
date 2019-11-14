//
//  Created by David Knothe on 14.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

// An operator which allows writing shorthand-return-nil statements, combined with logging the failure reason, as follows:
// return nil & debug.failure = ..., or
// return nil & {debug.failure = ...}

infix operator & : NilDebugPrecedence
precedencegroup NilDebugPrecedence {
    lowerThan: AssignmentPrecedence
}

func &<T>(lhs: T?, rhs: () -> Void) -> T? {
    rhs()
    return nil
}

func &<T>(lhs: T?, rhs: @autoclosure () -> Void) -> T? {
    rhs()
    return nil
}
