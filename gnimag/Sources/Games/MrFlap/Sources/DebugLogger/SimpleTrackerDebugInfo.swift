//
//  Created by David Knothe on 18.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import MacTestingTools

/// SimpleTrackerDebugInfo describes information about a SimpleTracker at a given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
struct SimpleTrackerDebugInfo: CustomStringConvertible {
    var dataSet: HasScatterDataSet?
    var regression: Function?
    var validityResult: ValidityResult?

    /// Fill "regression" with the regression from the given tracker.
    mutating func from<T: SimpleTrackerProtocol>(tracker: T) {
        dataSet = tracker
        regression = tracker.regression
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
    var description: String {
        "(dataPoints: \(dataSet?.dataSet.count ??? "nil"), regression: \(regression ??? "nil"), validityResult: \(validityResult?.description ??? "nil"))"
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
