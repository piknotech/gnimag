//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

infix operator ×

/// Calculate the cartesian product of two arrays.
public func ×<S, T>(lhs: [S], rhs: [T]) -> [(S, T)] {
    lhs.flatMap { l in
        rhs.map { r in
            (l, r)
        }
    }
}

public func a() {
    let b = [1,2] × [3,4]
    print(b)
}
