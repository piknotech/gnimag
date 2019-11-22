//
//  Created by David Knothe on 18.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import MacTestingTools

/// SimpleTrackerDebugInfo describes information about a SimpleTracker at a given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
struct SimpleTrackerDebugInfo: CustomStringConvertible {
    private(set) var dataSetProvider: HasScatterDataSet?
    private(set) var dataSet: [ScatterDataPoint]? // The data set is only evaluated when required.

    private(set) var regression: Function?
    fileprivate(set) var validityResult: ValidityResult?

    /// Initialize this instance with values from the given tracker.
    mutating func from<T: SimpleTrackerProtocol>(tracker: T) {
        dataSetProvider = tracker
        regression = tracker.regression
    }

    /// Get the data set from the data set provider and store it.
    mutating func fetchDataSet() {
        dataSet = dataSetProvider?.dataSet
    }

    enum ValidityResult {
        case valid
        case invalid(value: Double, expected: Double, tolerance: TrackerTolerance, wasFallback: Bool)
        case fallbackInvalid

        /// Description of the result, using uppercase letters if it was invalid.
        var description: String {
            switch self {
            case .valid:
                return ".valid"

            case let .invalid(value: value, expected: expected, tolerance: tolerance, wasFallback: wasFallback):
                return ".INVALID(value: \(value), expected: \(expected), tolerance: \(tolerance), wasFallback: \(wasFallback)"

            case .fallbackInvalid:
                return ".FALLBACK_INVALID"
            }
        }
    }

    /// Nice textual description of this instance.
    /// Call "fetchDataSet" before describing this instance.
    var description: String {
        "(dataPoints: \(dataSet?.count ??? "nil"), regression: \(regression ??? "nil"), validityResult: \(validityResult?.description ??? "nil"))"
    }
}

// Extensions for SimpleTrackers to simply allow filling "validityResult" of a SimpleTrackerDebugInfo without additional code

extension SimpleTrackerProtocol {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided SimpleTrackerDebugInfo.
    func `is`(_ value: Value, at time: Time, validWith tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid, _ debug: inout SimpleTrackerDebugInfo) -> Bool {
        let result = self.is(value, at: time, validWith: tolerance, fallbackWhenNoRegression: .valid)

        // Fill validityResult according to result
        if result {
            debug.validityResult = .valid
        } else {
            if fallback == .invalid {
                debug.validityResult = .fallbackInvalid
            } else {
                let wasFallback = regression == nil // fallback: .useLastValue was used
                debug.validityResult = .invalid(value: value, expected: regression?.at(time) ?? values.last!, tolerance: tolerance, wasFallback: wasFallback)
            }
        }

        return result
    }
}

extension ConstantTracker {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided SimpleTrackerDebugInfo.
    func `is`(_ value: Value, validWith tolerance: TrackerTolerance, fallback: TrackerFallbackMethod = .valid, _ debug: inout SimpleTrackerDebugInfo) -> Bool {
        self.is(value, at: .zero, validWith: tolerance, fallback: fallback, &debug)
    }
}
