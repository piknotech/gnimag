//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import MacTestingTools

/// Circular provides a wrapper around trackers whose value range is in [0, 2pi).
/// It maps those angular values to linear values (in R).
public final class Circular<Other: PolyTracker>: SimpleTracker {
    /// The internal tracker tracking the linearified values.
    fileprivate let tracker: Other

    /// Get the linearified regression.
    public var hasRegression: Bool { tracker.hasRegression }
    public var regression: Polynomial<Value>? { tracker.regression }

    /// Default initializer.
    public init(_ tracker: Other) {
        self.tracker = tracker
    }
    
    /// Linearify the value and add it to the tracker.
    public func add(value: Other.Value, at time: Other.Time) {
        let linearValue = linearify(value, at: time)
        tracker.add(value: linearValue, at: time)
    }

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    public override func `is`(_ value: Value, at time: Time, validWith tolerance: Tolerance, fallbackWhenNoRegression: FallbackMethod = .valid) -> Bool {
        let linearValue = linearify(value, at: time)
        return tracker.is(linearValue, at: time, validWith: tolerance, fallbackWhenNoRegression: fallbackWhenNoRegression)
    }

    /// Convert a given angular value in [0, 2pi) to a linear value that is directly near the estimated tracker value.
    /// When no regression is available, it uses the last value. When no last value is available, the value is returned unchanged.
    public func linearify(_ value: Other.Value, at time: Other.Value) -> Double {
        guard let guess = tracker.regression?.at(time) ?? tracker.lastValue else { return value }
        
        let distance = guess - value
        let rotations = floor((distance + .pi) / (2 * .pi))
        let linearValue = value + rotations * 2 * .pi
        return linearValue
    }
}

// MARK: Has2DDataSet (for MacTestingTools)
extension Circular: Has2DDataSet {
    /// Return the current raw data from the tracker.
    public func yieldDataSet() -> (xValues: [Double], yValues: [Double]) {
        return tracker.yieldDataSet()
    }
}
