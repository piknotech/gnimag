//
//  Created by David Knothe on 17.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A helper tool which checks whether an incoming value stream is (strictly) monotone.
public final class MonotonicityChecker<T: Comparable> {
    public enum Direction {
        /// The sequence must be monotonically increasing.
        case increasing
        /// The sequence must be monotonically decreasing.
        case decreasing
        /// The sequence must either be monotonically increasing or monotonically decreasing.
        case both

        /// The integral value of the direction:
        /// 1 when increasing, -1 when decreasing and nil when both.
        public var intValue: Int? {
            switch self {
            case .increasing: return 1
            case .decreasing: return -1
            case .both: return nil
            }
        }
    }

    /// The determined monotonicity direction.
    /// When `.both`, the direction is not yet determined.
    public private(set) var direction: Direction

    /// When `strict`, the values must be strictly monotone, which means that equality is already a failure of monotonicity.
    private let strict: Bool

    /// The most recently verified value.
    public private(set) var lastValue: T!

    /// Default initializer.
    public init(direction: Direction, strict: Bool) {
        self.direction = direction
        self.strict = strict
    }

    /// Check if the value satisfies the required monotonicity and store it as most recent value.
    /// If the value doesn't match, only update the most recent value if `stillUpdateOnFailure` is true (default: false).
    public func verify(value: T, stillUpdateOnFailure: Bool = false) -> Bool {
        // Nothing to decide for the very first value
        guard lastValue != nil else {
            lastValue = value
            return true
        }

        switch direction {
        case .increasing:
            let result = strict ? value > lastValue : value >= lastValue
            if result || stillUpdateOnFailure { lastValue = value }
            return result

        case .decreasing:
            let result = strict ? value < lastValue : value <= lastValue
            if result || stillUpdateOnFailure { lastValue = value }
            return result

        case .both:
            // Decide the direction, unless the value is exactly equal the last value
            if value == lastValue { return !strict }
            if value < lastValue { direction = .decreasing }
            if value > lastValue { direction = .increasing }
            lastValue = value
            return true
        }
    }
}
