//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

extension Array {
    /// Scan the array from front to back, performing an operation for each element with the current partial result, and return all partial results at the end.
    /// The size of the result is 1 larger than the size of `self`.
    @_transparent
    public func scan<T>(initial: T, includeInitial: Bool = true, _ f: (T, Element) -> T) -> [T] {
        var result = includeInitial ? [initial] : []

        for elem in self {
            result.append(f(result.last ?? initial, elem))
        }

        return result
    }
}
