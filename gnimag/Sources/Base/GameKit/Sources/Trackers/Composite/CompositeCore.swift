//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

public final class CompositeCore {
    public typealias Time = Double
    public typealias Value = Double

    // MARK: Subtypes
    
    /// Chracteristics which describe how and when to make a segment advancement decision.
    struct NextSegmentDecisionCharacteristics {
        /// The number of points which must match the next segment.
        /// When this is 1, `maxIntermediatePointsMatchingCurrentSegment` is irrelevant, as there are no intermediate points.
        let pointsMatchingNextSegment: Int

        /// During the interval in which `pointsMatchingNextSegment` points matching the next segment are collected, at most `maxIntermediatePointsMatchingCurrentSegment` are allowed to match the current, old segment.
        /// If more points match the current segment, the decision action is (partially) cancelled.
        let maxIntermediatePointsMatchingCurrentSegment: Int
    }

    enum State {
        case decidingToAdvance
        case missingDataPointsForCurrentTracker
        case normal
    }

    // MARK: Properties

    /// The delegate and data source which are both required.
    private var delegate: CompositeCoreDelegate!
    private var dataSource: CompositeCoreDataSource!

    /// The absolute tolerance for all segments/trackers.
    private let tolerance: Double

    /// Datasets with all data points (including invalid ones which have been checked in `is(value:validAt:)`, for plotting with ScatterPlot.
    public private(set) var allDataPoints = SimpleDataSet()

    /// Default initializer.
    public init(tolerance: Double) {
        self.tolerance = tolerance
    }

    // MARK: Methods

    /// Check if a given value is valid to be added to the tracker.
    /// This means that the value either matches the current or the next partial function.
    /// ONLY call `add(value:at:)` when the data point is validated by this method beforehand!
    public func `is`(value: Value, validAt time: Time) -> Bool {
        return true
    }

    /// Add a data point to the tracker.
    /// Added data points MUST be in time-monotonically order, meaning time is either increasing or decreasing permanently.
    /// Also, only add a data point when it is valid (using `is(value:validAt:)`)!
    public func add(value: Value, at time: Time) {
        
    }
}
