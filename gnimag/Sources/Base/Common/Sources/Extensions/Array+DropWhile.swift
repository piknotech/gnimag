//
//  Created by David Knothe on 09.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

extension Array {
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
