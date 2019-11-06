//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

infix operator ??=

/// Shorthand for lhs = lhs ?? rhs.
public func ??=<T>(lhs: inout Optional<T>, rhs: @autoclosure () -> Optional<T>) {
    lhs = lhs ?? rhs()
}
