//
//  Created by David Knothe on 05.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

extension Int {
    /// Perform a closure `self` times.
    @_transparent
    public func `repeat`<T>(_ closure: () -> T) {
        for _ in 0 ..< self {
            _ = closure()
        }
    }

    /// Return an array consisting of `self` subsequent executions of `closure`.
    @_transparent
    public func timesMake<T>(_ closure: () -> T) -> [T] {
        (0 ..< self).map { _ in return closure() }
    }
}
