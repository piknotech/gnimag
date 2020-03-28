//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// ArrayScanner provides a semantically appealing interface for scanning/traversing an array from beginning to end.
/// When the array is exhausted, the scanner stops and returns nil on subsequent calls.
struct ArrayScanner<T> {
    var array: [T]

    /// Move to the next value in the collection and return it.
    @discardableResult
    mutating func next() -> T? {
        if array.isEmpty { return nil }
        return array.removeFirst()
    }

    /// Look at the next value in the collection and return it, but remain at the current value.
    /// This means, consecutive calls to this method will return the same value.
    func peakNext() -> T? {
        array.first
    }
}
