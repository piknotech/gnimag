//
//  Created by David Knothe on 19.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import TestingTools

/// CompositeTrackerDebugInfo describes information about a CompositeTracker at a given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
class CompositeTrackerDebugInfo<T: SimpleTrackerProtocol>: TrackerDebugInfo, CustomStringConvertible {
    private(set) var tracker: CompositeTracker<T>?
    private(set) var allDataPoints: [ScatterDataPoint]? // The data set is only evaluated when required.
    private(set) var allFunctions: [FunctionDebugInfo]? // The functions are only evaluated when required.

    private(set) var segmentIndex: Int?
    private(set) var segmentRegression: Function?

    fileprivate(set) var validityResult: ValidityResult?

    /// Initialize this instance with values from the given tracker.
    func from(tracker: CompositeTracker<T>) {
        self.tracker = tracker
        segmentIndex = tracker.currentSegment.index
        segmentRegression = tracker.currentSegment.tracker.regression
    }

    /// Get the data set from the data set provider and store it.
    func fetchDataSet() {
        allDataPoints = tracker?.dataSet
    }

    /// Get function infos from the data set provider and store it.
    func fetchFunctionInfos() {
        allFunctions = tracker?.allDebugFunctionInfos
    }
    
    enum ValidityResult {
        case valid
        case invalid
    }

    /// Nice textual description of this instance.
    /// Call `fetchDataSet` before describing this instance.
    var description: String {
        "(dataPoints: \(allDataPoints?.count ??? "nil"), segmentIndex: \(segmentIndex ??? "nil"), segmentRegression: \(segmentRegression ??? "nil"), validityResult: \(validityResult ??? "nil"))"
    }

    /// Create a scatter plot with `allDataPoints` and `allFunctions`, if existing.
    /// Call `fetchDataSet` beforehand.
    func createScatterPlot() -> ScatterPlot? {
        guard let dataPoints = allDataPoints else { return nil }

        let plot = ScatterPlot(dataPoints: dataPoints)
        allFunctions?.forEach {
            plot.stroke($0.strokable, with: $0.color, alpha: 0.75, strokeWidth: 0.5, dash: $0.dash.concreteDash)
        }
        
        return plot
    }
}

// Extensions for CompositeTrackers to simply allow filling "validityResult" of a CompositeTrackerDebugInfo without additional code

extension CompositeTracker {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided CompositeTrackerDebugInfo.
    func integrityCheck(with value: Value, at time: Time, _ debug: inout CompositeTrackerDebugInfo<SegmentTrackerType>) -> Bool {
        let result = integrityCheck(with: value, at: time)
        debug.validityResult = result ? .valid : .invalid
        return result
    }
}
