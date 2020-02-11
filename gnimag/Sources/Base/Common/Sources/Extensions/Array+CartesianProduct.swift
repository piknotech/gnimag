//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

infix operator ×

/// Calculate the cartesian product of two arrays.
@_transparent
public func ×<S, T>(lhs: [S], rhs: [T]) -> [(S, T)] {
    lhs.flatMap { l in
        rhs.map { r in
            (l, r)
        }
    }
}

/// A performant version of (a × b).map(block).
@_transparent
public func cartesianMap<T, U, V>(_ array1: [T], _ array2: [U], block: (T, U) -> V) -> [V] {
    var result = [V]()
    result.reserveCapacity(array2.count * array2.count)

    // Use plain loops for a great performance increase in comparsion to ×/map
    for elem1 in array1 {
        for elem2 in array2 {
            result.append(block(elem1, elem2))
        }
    }

    return result
}
