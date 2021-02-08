//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

extension Sequence {
    /// Count the number of objects where "predicate" is fulfilled.
    @_transparent
    public func count(where predicate: (Element) -> Bool) -> Int {
        filter(predicate).count
    }

    /// Check iff any element fulfills the predicate.
    @_transparent
    public func any(where predicate: (Element) -> Bool) -> Bool {
        contains(where: predicate)
    }

    /// Check iff no element fulfills the predicate.
    @_transparent
    public func none(where predicate: (Element) -> Bool) -> Bool {
        !contains(where: predicate)
    }
}

extension Sequence {
    /// Map each element to a comparable property and return the element with the minimum property.
    @_transparent
    public func min<T: Comparable>(by property: (Element) -> T) -> Element? {
        var best: (elem: Element, value: T)?

        for elem in self {
            let value = property(elem)
            if best?.value == nil || best!.value > value {
                best = (elem, value)
            }
        }

        return best?.elem
    }

    @_transparent
    public func max<T: Comparable>(by property: (Element) -> T) -> Element? {
        min {
            Negative(value: property($0))
        }
    }
}

/// A comparable reversing the compared result.
public struct Negative<T: Comparable>: Comparable {
    public let value: T

    @_transparent
    public init(value: T) {
        self.value = value
    }

    @_transparent
    public static func < (lhs: Negative<T>, rhs: Negative<T>) -> Bool {
        lhs.value > rhs.value
    }
}
