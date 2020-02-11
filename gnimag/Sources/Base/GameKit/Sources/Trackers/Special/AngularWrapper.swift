//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import TestingTools

/// AngularWrapper provides a wrapper around simple trackers which would describe a simple function, but their values are angular, meaning a modulo-2-pi is applied.
/// This tracker undoes the modulo-2-pi step in order to produce the real base function (whose codomain is R instead of [0, 2*pi)).
public final class AngularWrapper<Other: SimpleTrackerProtocol>: SimpleTrackerProtocol {    
    public typealias F = Other.F
    
    /// The internal tracker tracking the linearified values.
    public private(set) var tracker: Other

    public var tolerance: TrackerTolerance {
        get { tracker.tolerance }
        set { tracker.tolerance = newValue }
    }
    /// Default initializer.
    public init(_ tracker: Other) {
        self.tracker = tracker
    }

    // MARK: Forwarded Methods And Properties
    public var times: [Time] { tracker.times }
    public var values: [Value] { tracker.values }
    public var maxDataPoints: Int { tracker.maxDataPoints }
    public var requiredPointsForCalculatingRegression: Int { tracker.requiredPointsForCalculatingRegression }
    public var regression: F? { tracker.regression }

    public func updateRegression() { tracker.updateRegression() }
    public func reset() { tracker.reset() }
    public func removeLast() { tracker.removeLast() }

    public func scatterStrokable(for function: F) -> ScatterStrokable {
        tracker.scatterStrokable(for: function)
    }

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
    public func isDataPointValid(value: Value, time: Time, fallback: TrackerFallbackMethod = .valid) -> Bool {
        let linearValue = linearify(value, at: time)
        return tracker.isDataPointValid(value: linearValue, time: time, fallback: fallback)
    }

    /// Perform a validity check, but with a different tolerance value.
    /// This does not affect `self.tolerance`.
    public func isDataPoint(value: Value, time: Time, validWithTolerance tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid) -> Bool {
        let linearValue = linearify(value, at: time)
        return tracker.isDataPoint(value: linearValue, time: time, validWithTolerance: tolerance, fallback: fallback)
    }

    /// Return a ScatterStrokable which describes the valid tolerance range around the given point, respective to the current tolerance and the given regression function. For debugging.
    public final func scatterStrokable(forToleranceRangeAroundTime time: Time, value: Value, f: F) -> ScatterStrokable {
        let linearValue = linearify(value, at: time)
        return tracker.scatterStrokable(forToleranceRangeAroundTime: time, value: linearValue, f: f)
    }
}
