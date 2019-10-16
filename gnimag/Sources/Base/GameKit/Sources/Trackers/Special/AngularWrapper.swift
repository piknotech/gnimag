//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import MacTestingTools

/// AngularWrapper provides a wrapper around simple trackers which would describe a simple function, but their values are angular, meaning a modulo-2-pi is applied.
/// This tracker undoes the modulo-2-pi step in order to produce the real base function (whose codomain is R instead of [0, 2*pi)).
public final class AngularWrapper<Other: SimpleTrackerProtocol>: SimpleTrackerProtocol {
    /// The internal tracker tracking the linearified values.
    private let tracker: Other

    /// Default initializer.
    public init(_ tracker: Other) {
        self.tracker = tracker
    }

    // MARK: Forwarded Methods And Properties
    public var times: [Time] { tracker.times }
    public var values: [Value] { tracker.values }
    public var maxDataPoints: Int { tracker.maxDataPoints }
    public var requiredPointsForCalculatingRegression: Int { tracker.requiredPointsForCalculatingRegression }
    public var regression: SmoothFunction? { tracker.regression }

    public func updateRegression() { tracker.updateRegression() }
    public func reset() { tracker.reset() }
    public func removeLast() { tracker.removeLast() }

    // MARK: Linearification
    /// Convert a given angular value in [0, 2pi) to a linear value that is directly near the estimated tracker value.
    /// When no regression is available, it uses the last value. When no last value is available, the value is returned unchanged.
    public func linearify(_ value: Value, at time: Time) -> Double {
        guard let guess = regression?.at(time) ?? values.last else { return value }

        let distance = guess - value
        let rotations = floor((distance + .pi) / (2 * .pi))
        let linearValue = value + rotations * 2 * .pi
        return linearValue
    }

    /// Linearify the value and add it to the tracker.
    public func add(value: Value, at time: Time, updateRegression: Bool = true) {
        let linearValue = linearify(value, at: time)
        tracker.add(value: linearValue, at: time, updateRegression: updateRegression)
    }

    /// Check if a value will be valid (compared to the expected value) at a given time, using the existing regression.
    /// If there is no regression, use the specified fallback.
    public func `is`(_ value: Value, at time: Time, validWith tolerance: TrackerTolerance, fallbackWhenNoRegression: TrackerFallbackMethod) -> Bool {
        let linearValue = linearify(value, at: time)
        return tracker.is(linearValue, at: time, validWith: tolerance, fallbackWhenNoRegression: fallbackWhenNoRegression)
    }
}