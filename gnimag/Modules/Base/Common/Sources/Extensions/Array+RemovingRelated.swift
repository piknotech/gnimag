//
//  Created by David Knothe on 09.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//
// RemoveAtIndices: Taken from https://forums.swift.org/t/removing-elements-at-more-than-one-index-from-an-array/19953/6

import Foundation

// MARK: DropWhile

extension Array {
    /// If `self` has more than `maxCount` elements, remove the first `count - maxCount` elements.
    @_transparent
    public mutating func trim(maxCount: Int) {
        if count > maxCount {
            removeFirst(count - maxCount)
        }
    }

    /// Drop elements, beginning at the start of the array, while `predicate` is fulfilled.
    /// This is done in-place. Return the elements which have been dropped.
    @_transparent
    @discardableResult
    public mutating func dropWhile(predicate: (Element) -> Bool) -> [Element] {
        var dropped = [Element]()

        for elem in self {
            if predicate(elem) {
                removeFirst()
                dropped.append(elem)
            } else {
                break // Finished here
            }
        }

        return dropped
    }
}

// MARK: RemoveAtIndices

extension Array {
    /// An efficient way to remove multiple indices from an array at once.
    @discardableResult
    public mutating func remove(atIndices indicesToRemove: [Int]) -> [Element] {
        guard !indicesToRemove.isEmpty else {
            return []
        }

        // Copy the removed elements in the specified order.
        let removedElements = indicesToRemove.map { self[$0] }

        // Sort the indices to remove.
        let indicesToRemove = indicesToRemove.sorted()

        // Shift the elements we want to keep to the left.
        var destIndex = indicesToRemove.first!
        var srcIndex = destIndex + 1
        func shiftLeft(untilIndex index: Int) {
            while srcIndex < index {
                self[destIndex] = self[srcIndex]
                destIndex += 1
                srcIndex += 1
            }
            srcIndex += 1
        }

        for removeIndex in indicesToRemove[1...] {
            shiftLeft(untilIndex: removeIndex)
        }
        shiftLeft(untilIndex: self.endIndex)

        // Remove the extra elements from the end of the array.
        self.removeLast(indicesToRemove.count)

        return removedElements
    }
}

// MARK: RemoveByValue

extension Array where Element: Equatable {
    /// Return an array by removing all elements that are equal to the given value.
    @_transparent
    public func removing(_ value: Element) -> [Element] {
        filter { $0 != value }
    }
}
