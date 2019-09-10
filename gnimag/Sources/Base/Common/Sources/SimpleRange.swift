//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// SimpleRange defines a ClosedRange and provides some utilities.
/// When using floating-point types, it is also possible to create unbounded ranges using .infinity.
public struct SimpleRange<Bound: SignedNumeric & Comparable> {
    public let lower: Bound
    public let upper: Bound

    /// Default initializer.
    public init(from lower: Bound, to upper: Bound) {
        self.lower = lower
        self.upper = upper
    }

    /// States if the range is empty.
    public var isEmpty: Bool {
        upper > lower
    }

    /// Negate the range in the following sense:
    /// [a, b] -> [-b, -a].
    public var negated: SimpleRange<Bound> {
        return SimpleRange(from: -upper, to: -lower)
    }

    /// Shift the range in the following sense:
    /// [a, b] -> [a+c, b+c].
    public func shifted(by amount: Bound) -> SimpleRange<Bound> {
        return SimpleRange(from: lower + amount, to: upper + amount)
    }

    /// Check if the element is in the range.
    public func contains(_ element: Bound) -> Bool {
        return lower <= element && element <= upper
    }

    /// Intersect this range with another range.
    public func intersection(with other: SimpleRange<Bound>) -> SimpleRange<Bound> {
        return SimpleRange(from: max(lower, other.lower), to: min(upper, other.upper))
    }

    /// Clamp the element to [lower, upper].
    /// Only works when `isEmpty = false`.
    public func clamp(_ element: Bound) -> Bound {
        return min(max(element, lower), upper)
    }
}
