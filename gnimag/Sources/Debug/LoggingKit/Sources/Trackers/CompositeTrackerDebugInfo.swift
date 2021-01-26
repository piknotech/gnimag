//
//  Created by David Knothe on 19.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit
import TestingTools

/// CompositeTrackerDebugInfo describes information about a CompositeTracker at one single given frame.
/// This includes both general information like the regression and specific information about a single validity-check call.
public final class CompositeTrackerDebugInfo<T: SimpleTrackerProtocol>: CustomStringConvertible {
    private(set) var tracker: CompositeTracker<T>?
    public private(set) var allDataPoints: [ScatterDataPoint]? // The data set is only evaluated when required.
    public private(set) var allFunctions: [FunctionDebugInfo]? // The functions are only evaluated when required.

    public private(set) var segmentIndex: Int?
    public private(set) var segmentRegression: Function?

    public fileprivate(set) var validityResult: ValidityResult?

    /// A FunctionDebugInfo containing a ScatterStrokable (for example, ellipse or line) which shows the exact tolerance testing range around the latest tested data point, according to the current segment regression (NOT to the guesses for the next segment).
    /// Nil if the current tracker has no regression.
    public fileprivate(set) var toleranceRegionInfo: FunctionDebugInfo?

    /// Default initializer, creating an emtpy instance.
    public init() {
    }

    /// Initialize this instance with values from the given tracker.
    public func from(tracker: CompositeTracker<T>) {
        self.tracker = tracker
        segmentIndex = tracker.currentSegment.index
        segmentRegression = tracker.currentSegment.tracker.regression
    }

    /// Get the data set (for all segments) from the tracker and store them.
    public func fetchDataSet() {
        allDataPoints = tracker?.dataSet
    }

    /// Get the data set (for the most recent segments) from the tracker and store them.
    public func fetchDataSet(numSegments: Int) {
        allDataPoints = tracker?.dataSet(forMostRecentSegments: numSegments)
    }

    public enum FunctionInfoType {
        /// All regressions.
        /// This does not include each segment's tolerance bounds.
        case noGuesses

        /// All regressions and guesses.
        /// This does not include each segment's tolerance bounds.
        case all

        /// Debug infos from each segment, i.e. regressions and tolerance bounds.
        /// No guesses.
        case segmentwise
    }

    /// Get function infos (for the most recent segments) from the tracker and store them.
    public func fetchFunctionInfos(type: FunctionInfoType, numSegments: Int = .max) {
        switch type {
        case .noGuesses:
            allFunctions = tracker?.allDebugFunctionInfos(numSegments: numSegments, includeGuesses: false)
        case .all:
            allFunctions = tracker?.allDebugFunctionInfos(numSegments: numSegments, includeGuesses: true)
        case .segmentwise:
            allFunctions = tracker?.segmentwiseFullDebugFunctionInfos(numSegments: numSegments)
        }
    }

    public enum ValidityResult {
        case valid
        case invalid
    }

    /// Nice textual description of this instance.
    /// Call `fetchDataSet` before describing this instance.
    public var description: String {
        "(dataPoints: \(allDataPoints?.count ??? "nil"), segmentIndex: \(segmentIndex ??? "nil"), segmentRegression: \(segmentRegression ??? "nil"), validityResult: \(validityResult ??? "nil"))"
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
            plot.stroke(region.strokable, with: region.color, alpha: 0.75, strokeWidth: 1, dash: region.dash.concreteDash)
        }
        
        return plot
    }
}

// Extensions for CompositeTrackers to simply allow filling "validityResult" of a CompositeTrackerDebugInfo without additional code

public extension CompositeTracker {
    /// Perform a validity check on the tracker and write the result into "validityResult" of the provided CompositeTrackerDebugInfo.
    func integrityCheck(with value: Value, at time: Time, _ debug: inout CompositeTrackerDebugInfo<SegmentTrackerType>) -> Bool {
        let result = integrityCheck(with: value, at: time)

        // Fill validityResult
        debug.validityResult = result ? .valid : .invalid

        // Fill toleranceFunctionInfo
        debug.toleranceRegionInfo = lastToleranceRegionScatterStrokable.map { strokable in
            FunctionDebugInfo(function: nil, strokable: strokable, color: .emphasize, dash: .solid)
        }

        return result
    }
}
