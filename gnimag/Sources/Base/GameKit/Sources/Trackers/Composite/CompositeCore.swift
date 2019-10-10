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

    public enum State {
        /// One data point matched the next tracker – the following data points are evaluated to see if the decision characteristics are met. Then, the decision is either cancelled, deferred or made.
        /// Depending on the characteristics, this decision can take really long.
        case decidingToAdvance

        /// The segment has been advanced (or is the first one), but not enough data points are available to actually create the regression function.
        case missingDataPointsForCurrentTracker

        /// There exists a regression function for the current segment and there is no evidence of the next segment yet.
        case normal
    }

    /// Information about a segment, either the current segment or a previous one.
    class SegmentInfo {
        let index: Int
        let tracker: SimpleTrackerProtocol
        var minGuess: SmoothFunction?
        var maxGuess: SmoothFunction?

        init(index: Int, tracker: SimpleTrackerProtocol) {
            self.index = index
            self.tracker = tracker
        }
    }

    // MARK: Properties

    /// Info about the last and about the current segment.
    private var lastSegment: SegmentInfo?
    private var currentSegment: SegmentInfo!

    /// The index of the current segment, starting at 0. Each time a new segment is detected, this increases by 1.
    public var currentSegmentIndex: Int { currentSegment.index }

    /// The current state.
    public private(set) var state = State.missingDataPointsForCurrentTracker

    /// The delegate and data source which are both required.
    private let delegate: CompositeCoreDelegate
    private let dataSource: CompositeCoreDataSource

    /// The absolute tolerance for all segments/trackers.
    private let tolerance: Double

    /// A dataset with all data points (including invalid ones which have been checked in `is(value:validAt:)`, for plotting with ScatterPlot.
    public private(set) var allDataPoints = SimpleDataSet()

    /// Default initializer.
    public init(tolerance: Double, delegate: CompositeCoreDelegate, dataSource: CompositeCoreDataSource) {
        self.tolerance = tolerance
        self.delegate = delegate
        self.dataSource = dataSource

        // Create initial tracker
        let tracker = dataSource.trackerForNextSegment()
        currentSegment = SegmentInfo(index: 0, tracker: tracker)
    }

    // MARK: Methods

    /// Add a data point to the tracker if it is valid.
    /// Return true iff the value is valid and it was added to the tracker.
    /// Data points MUST be added in time-monotonically order, meaning time is either increasing or decreasing permanently.
    public func add(value: Value, at time: Time) -> Bool {
        // Add to current segment, if matching
        if currentSegmentMatches(value: value, at: time) {
            // ...
            return true
        }

        // Add to next segment, if matching
        if nextSegmentMatches(value: value, at: time) {
            // ...
            return true
        }

        // Value was invalid – still add to `allDataPoints` for plotting
        allDataPoints.add(time: time, value: value, color: .invalid)
        return false
    }

    /// Check if the data point matches the current segment regression.
    private func currentSegmentMatches(value: Value, at time: Time) -> Bool {
        // Regression function available
        if let regression = currentSegment.tracker.regression {
            return abs(regression.at(time) - value) <= tolerance
        }

        // Min and max guess available
        if let min = currentSegment.minGuess, let max = currentSegment.maxGuess {
            return self.value(value, at: time, matchesInteriorOf: min, and: max)
        }

        // Too little data points
        return true
    }

    /// Check if the data point matches the predicted next segment (using the guess from the `dataSource`).
    private func nextSegmentMatches(value: Value, at time: Time) -> Bool {
        guard let lastTime = currentSegment.tracker.times.last else { return false }

        // Assume monotonicity in the small interesting segment – make just 2 guesses.
        // Making more guesses (and also extending the guess interval further to the left) could make the prediction accuracy better.
        guard let guess1 = dataSource.guessForNextPartialFunction(whenSplittingSegmentsAt: lastTime),
            let guess2 = dataSource.guessForNextPartialFunction(whenSplittingSegmentsAt: time) else { return false }

        return self.value(value, at: time, matchesInteriorOf: guess1, and: guess2)
    }

    /// Check if the value is either inside the two functions, or is near enough to one of the two functions (using the CompositeCore's tolerance).
    private func value(_ value: Value, at time: Time, matchesInteriorOf min: SmoothFunction, and max: SmoothFunction) -> Bool {
        let value1 = min.at(time), value2 = max.at(time)
        let min = Swift.min(value1, value2), max = Swift.max(value1, value2)

        return (min <= value && value <= max) || abs(min - value) <= tolerance || abs(max - value) <= tolerance
    }
}
