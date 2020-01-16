//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// SimpleRange defines a floating-point range and provides some utilities.
/// It is also possible to create unbounded ranges using .infinity.
public struct SimpleRange<Bound: FloatingPoint> {
    public let lower: Bound
    public let upper: Bound

    /// Default initializer.
    /// If `enforceRegularity`, `from` and `to` are swapped, if required, to guarantee `lower <= upper`.
    /// Else, `from` and `to` are left as-is. Defaults to false.
    public init(from lower: Bound, to upper: Bound, enforceRegularity: Bool = false) {
        self.lower = enforceRegularity ? min(lower, upper) : lower
        self.upper = enforceRegularity ? max(lower, upper) : upper
    }

    /// Create a range around a given point with a given size.
    public init(around center: Bound, diameter: Bound) {
        self.lower = center - diameter / 2
        self.upper = center + diameter / 2
    }

    /// The open range, from -inf to +inf.
    public static var open: SimpleRange { .init(from: -.infinity, to: .infinity) }
    public static var positiveHalfOpen: SimpleRange { .init(from: 0, to: .infinity) }
    public static var negativeHalfOpen: SimpleRange { .init(from: -.infinity, to: 0) }

    /// A range with the same bounds, but regularized if required.
    /// A regular range always has `lower <= upper`, which means that a regular range is never empty.
    public var regularized: SimpleRange<Bound> {
        SimpleRange(from: lower, to: upper, enforceRegularity: true)
    }

    /// States if the range is empty, i.e. `upper < lower`.
    /// A range containing a single element is not empty!
    public var isEmpty: Bool {
        upper < lower
    }

    /// States if the range consists of a single element, i.e. `upper == lower`.
    public var isSinglePoint: Bool {
        upper == lower
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
    /// Only works when `isEmpty = false`.
    public func contains(_ element: Bound) -> Bool {
        return lower <= element && element <= upper
    }

    /// Intersect this range with another range.
    /// Only works when `isEmpty = false`.
    /// Returns an empty range if there is no intersection.
    public func intersection(with other: SimpleRange<Bound>) -> SimpleRange<Bound> {
        return SimpleRange(from: max(lower, other.lower), to: min(upper, other.upper))
    }

    /// Clamp the element to [lower, upper].
    /// Only works when `isEmpty = false`.
    public func clamp(_ element: Bound) -> Bound {
        return min(max(element, lower), upper)
    }
}
