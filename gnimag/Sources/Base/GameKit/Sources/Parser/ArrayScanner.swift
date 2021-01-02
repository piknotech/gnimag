//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// ArrayScanner provides a semantically appealing interface for scanning/traversing an array from beginning to end.
/// When the array is exhausted, the scanner stops and returns nil on subsequent calls.
public struct ArrayScanner<T> {
    private var array: [T]

    /// Default initializer.
    public init(_ array: [T]) {
        self.array = array
    }

    /// Move to the next value in the collection and return it.
    @discardableResult
    public mutating func next() -> T? {
        if array.isEmpty { return nil }
        return array.removeFirst()
    }

    /// Look at the next value in the collection and return it, but remain at the current value.
    /// This means, consecutive calls to this method will return the same value.
    public func peakNext() -> T? {
        array.first
    }
}
