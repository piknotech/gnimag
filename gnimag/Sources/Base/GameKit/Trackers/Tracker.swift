//
//  Created by David Knothe on 09.04.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Tracker defines a common, unified interface for trackers.
/// Because Swift protocols do neither allow default arguments nor nested classes, this is an abstract class.
/*abstract*/ public class Tracker {
    public typealias Time = Double
    public typealias Value = Double

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback.
    public func `is`(_ value: Value, at time: Time, validWith tolerance: Tolerance, fallbackWhenNoRegression: FallbackMethod = .valid) -> Bool {
        fatalError("This is an abstract class. Please implement this method in your subclass.")
    }

    public enum Tolerance {
        /// Look at the difference between the expected value and the average value.
        /// Iff it is smaller than or equal to tolerance, return true.
        case absolute(tolerance: Value)

        /// Look at the difference between the expected value and the average value.
        /// Iff it is smaller than or equal to (tolerance * expectedValue), return true.
        case relative(tolerance: Value)
    }

    public enum FallbackMethod {
        /// Return true when no regression is available.
        case valid

        /// Return false when no regression is available.
        case invalid

        /// Use the last added value when no regression is available.
        /// When there is no last added value, crash.
        case useLastValue
    }
}
