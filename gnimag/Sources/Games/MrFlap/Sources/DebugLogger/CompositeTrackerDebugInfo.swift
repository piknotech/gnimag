//
//  Created by David Knothe on 19.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import MacTestingTools

/// CompositeTrackerDebugInfo describes information about a CompositeTracker at a given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
struct CompositeTrackerDebugInfo: CustomStringConvertible {
    var dataSet: HasScatterDataSet?
    var segmentIndex: Int?
    var segmentRegression: Function?
    var validityResult: ValidityResult?

    /// Fill "regression" with the regression from the given tracker.
    mutating func from<T: SimpleTrackerProtocol>(tracker: CompositeTracker<T>) {
        dataSet = tracker.allDataPoints
        segmentIndex = tracker.currentSegment.index
        segmentRegression = tracker.currentSegment.tracker.regression
    }

    enum ValidityResult {
        case valid
        case invalid
    }

    /// Nice textual description of this instance.
    var description: String {
        "(dataPoints: \(dataSet?.dataSet.count ??? "nil"), segmentIndex: \(segmentIndex ??? "nil"), segmentRegression: \(segmentRegression ??? "nil"), validityResult: \(validityResult ??? "nil"))"
    }
}

// Extensions for CompositeTrackers to simply allow filling "validityResult" of a CompositeTrackerDebugInfo without additional code

extension CompositeTracker {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided CompositeTrackerDebugInfo.
    func integrityCheck(with value: Value, at time: Time, _ debug: inout CompositeTrackerDebugInfo) -> Bool {
        let result = integrityCheck(with: value, at: time)
        debug.validityResult = result ? .valid : .invalid
        return result
    }
}
