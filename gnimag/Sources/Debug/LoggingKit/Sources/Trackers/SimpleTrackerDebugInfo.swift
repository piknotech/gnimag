//
//  Created by David Knothe on 18.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit
import TestingTools

/// SimpleTrackerDebugInfo describes information about a SimpleTracker at a given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
public final class SimpleTrackerDebugInfo<Tracker: SimpleTrackerProtocol>: TrackerDebugInfo, CustomStringConvertible {
    public private(set) var tracker: Tracker?
    public private(set) var allDataPoints: [ScatterDataPoint]? // The data set is only evaluated when required.
    public private(set) var allFunctions: [FunctionDebugInfo]? // The functions are only evaluated when required.

    public private(set) var regression: Function?
    public fileprivate(set) var validityResult: ValidityResult?

    /// A FunctionDebugInfo containing a ScatterStrokable (for example, ellipse or line) which shows the exact tolerance testing range around the latest tested data point. Non-nil iff `validityResult` is `.some(.valid) or .some(.invalid)`.
    public fileprivate(set) var toleranceRegionInfo: FunctionDebugInfo?

    /// Default initializer, creating an emtpy instance.
    public init() {
    }
    
    /// Initialize this instance with values from the given tracker.
    public func from(tracker: Tracker) {
        self.tracker = tracker
        regression = tracker.regression
    }

    /// Get the data set from the data set provider and store it.
    public func fetchDataSet() {
        allDataPoints = tracker?.dataSet
    }

    /// Get function infos from the data set provider and store it.
    public func fetchFunctionInfos() {
        allFunctions = tracker?.allDebugFunctionInfos
    }

    public enum ValidityResult {
        case valid
        case invalid(value: Double, expected: Double, tolerance: TrackerTolerance, wasFallback: Bool)
        case fallbackInvalid

        /// Description of the result, using uppercase letters if it was invalid.
        var description: String {
            switch self {
            case .valid:
                return "valid"

            case let .invalid(value: value, expected: expected, tolerance: tolerance, wasFallback: wasFallback):
                return "INVALID(value: \(value), expected: \(expected), tolerance: \(tolerance), wasFallback: \(wasFallback)"

            case .fallbackInvalid:
                return "FALLBACK_INVALID"
            }
        }
    }

    /// Nice textual description of this instance.
    /// Call "fetchDataSet" before describing this instance.
    public var description: String {
        "(dataPoints: \(allDataPoints?.count ??? "nil"), regression: \(regression ??? "nil"), validityResult: \(validityResult?.description ??? "nil"))"
    }

    /// Create a scatter plot with `allDataPoints` and `allFunctions`, if existing.
    /// Call `fetchDataSet` beforehand.
    public func createScatterPlot(includeToleranceRegionForLastDataPoint: Bool = true) -> ScatterPlot? {
        guard let dataPoints = allDataPoints else { return nil }

        // Plot data points
        let plot = ScatterPlot(dataPoints: dataPoints)

        // Plot regression and tolerance functions
        allFunctions?.forEach {
            plot.stroke($0.strokable, with: $0.color, alpha: 0.75, strokeWidth: 0.5, dash: $0.dash.concreteDash)
        }

        // Plot tolerance region for last data point
        if includeToleranceRegionForLastDataPoint, let region = toleranceRegionInfo {
            plot.stroke(region.strokable, with: region.color, alpha: 0.7, strokeWidth: 0.5, dash: region.dash.concreteDash)
        }

        return plot
    }
}

// Extensions for SimpleTrackers to simply allow filling "validityResult" of a SimpleTrackerDebugInfo without additional code

public extension SimpleTrackerProtocol {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided SimpleTrackerDebugInfo.
    func isDataPointValid(value: Value, time: Time, fallback: TrackerFallbackMethod = .valid, _ debug: inout SimpleTrackerDebugInfo<Self>) -> Bool {
        let result = isDataPointValid(value: value, time: time, fallback: fallback)

        // Fill validityResult
        if result {
            debug.validityResult = .valid
        }
        else {
            if !hasRegression && fallback == .invalid {
                debug.validityResult = .fallbackInvalid
            } else {
                debug.validityResult = .invalid(value: value, expected: regression?.at(time) ?? values.last!, tolerance: tolerance, wasFallback: !hasRegression)
            }
        }

        // Fill toleranceFunctionInfo
        guard let f = regression else { return result }
        let toleranceStrokable = scatterStrokable(forToleranceRangeAroundTime: time, value: value, f: f)
        debug.toleranceRegionInfo = FunctionDebugInfo(function: nil, strokable: toleranceStrokable, color: .emphasize, dash: .solid)

        return result
    }
}

public extension ConstantTracker {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided SimpleTrackerDebugInfo.
    func isValueValid(_ value: Value, fallback: TrackerFallbackMethod = .valid, _ debug: inout SimpleTrackerDebugInfo<ConstantTracker>) -> Bool {
        isDataPointValid(value: value, time: count, fallback: fallback, &debug)
    }
}
