//
//  Created by David Knothe on 23.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A FixedSizeFIFO wraps an array of fixed size. Once the capacity of the array is surpassed, earliest elements are removed.
public struct FixedSizeFIFO<T> {
    public private(set) var elements = Array<T>()
    public let capacity: Int

    /// Initialize with empty contents.
    public init(capacity: Int) {
        self.capacity = capacity
    }

    /// Initialize with elements.
    /// If `contents.count > capacity`, the first elements of `contents` are removed.
    public init(contents: [T], capacity: Int) {
        self.elements = contents
        self.capacity = capacity
    }

    /// Append an element at the end of the array. If the capacity is surpassed, the first element is removed.
    public mutating func append(_ element: T) {
        elements.append(element)
        enforeCapacity()
    }

    /// Remove the first few elements of `elements` if `elements` exceeds the capacity.
    private mutating func enforeCapacity() {
        if elements.count > capacity {
            elements.removeFirst(elements.count - capacity)
        }
    }
}
