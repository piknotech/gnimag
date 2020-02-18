//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//
// Taken from https://forums.swift.org/t/removing-elements-at-more-than-one-index-from-an-array/19953/6

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
