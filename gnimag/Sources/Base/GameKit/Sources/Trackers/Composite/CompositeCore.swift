//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

/// CompositeCore provides the basic required functionalities for a composite tracker; that is, a tracker which tracks a piecewise defined funtion.
/// When creating a composite tracker, use a CompositeCore object and assign yourself as the delegate and data source.
/// Then, instead of adding values to your tracker directly, add them to the CompositeCore object and let it handle the task of detecting when a new function segment begins.
public final class CompositeCore: CompositeCoreSlidingWindowDelegate {
    public typealias Time = Double
    public typealias Value = Double

    // MARK: Subtypes
    
    /// Chracteristics which describe how and when to make a segment advancement decision.
    public struct NextSegmentDecisionCharacteristics {
        /// The number of points which must match the next segment.
        /// When this is 1, `maxIntermediatePointsMatchingCurrentSegment` is irrelevant, as there are no intermediate points.
        let pointsMatchingNextSegment: Int

        /// During the interval in which `pointsMatchingNextSegment` points matching the next segment are collected, at most `maxIntermediatePointsMatchingCurrentSegment` are allowed to match the current, old segment.
        /// If more points match the current segment, the decision action is (partially) cancelled.
        let maxIntermediatePointsMatchingCurrentSegment: Int
    }

    /// Information about a segment, either the current segment or a previous one.
    public struct SegmentInfo {
        public let index: Int
        public let tracker: SimpleTrackerProtocol

        /// When the tracker has no regression yet, use the guesses (which come from the last segment) for approximated functions and values.
        public let guesses: Guesses?
    }

    /// Guesses are used for two things:
    /// - Checking if a point is valid in the current segment, when the current segment has no regression yet
    /// - Checking if a point is valid in the next segment (as the next segment cannot have a regression before it is created)
    public struct Guesses {
        let min: SmoothFunction
        let max: SmoothFunction
    }

    // MARK: Properties

    /// The sliding window where data points are forwarded to.
    /// The points are then received via delegate callbacks.
    private let window: CompositeCoreSlidingWindow

    /// Up-to-date information about the current segment.
    private var currentSegment: SegmentInfo

    /// The most recent guesses that have been made for the next segment. When the next segment is actually created, these guesses are used.
    private var mostRecentGuessesForNextSegment: Guesses?

    /// The index of the current segment, starting at 0. Each time a new segment is detected, this increases by 1.
    public var currentSegmentIndex: Int { currentSegment.index }

    /// The delegate and data source which are both required.
    private unowned let delegate: CompositeCoreDelegate
    private unowned let dataSource: CompositeCoreDataSource

    /// The absolute tolerance for all segments/trackers.
    private let tolerance: Double

    /// A dataset with all data points (including invalid ones which have been checked in `is(value:validAt:)`, for plotting with ScatterPlot.
    public private(set) var allDataPoints = SimpleDataSet()

    private var currentColorForPlotting: ScatterDataPoint.Color {
        currentSegmentIndex.isMultiple(of: 2) ? .even : .odd
    }

    /// Default initializer.
    public init(tolerance: Double, decisionCharacteristics: NextSegmentDecisionCharacteristics, delegate: CompositeCoreDelegate, dataSource: CompositeCoreDataSource) {
        self.tolerance = tolerance
        self.delegate = delegate
        self.dataSource = dataSource
        self.window = CompositeCoreSlidingWindow(characteristics: decisionCharacteristics)

        // Create initial tracker
        let tracker = dataSource.trackerForNextSegment()
        currentSegment = SegmentInfo(index: 0, tracker: tracker, guesses: nil)
    }

    // MARK: Public Methods

    /// Add a data point to the tracker if it is valid.
    /// Return true iff the value is valid and it was added to the tracker.
    /// Data points MUST be added in time-monotonically order, meaning time is either increasing or decreasing permanently.
    public func add(value: Value, at time: Time) -> Bool {
        // Add to current segment, if matching
        if currentSegmentMatches(value: value, at: time) {
            window.addDataPoint(value: value, time: time, matching: .current)
            return true
        }

        // Add to next segment, if matching
        updateNextSegmentGuesses()
        if nextSegmentMatches(value: value, at: time) {
            window.addDataPoint(value: value, time: time, matching: .next)
            return true
        }

        // Value was invalid – still add to `allDataPoints` for plotting
        allDataPoints.add(value: value, time: time, color: .invalid)
        return false
    }

    // MARK: Private Methods

    /// Check if the data point matches the current segment regression.
    private func currentSegmentMatches(value: Value, at time: Time) -> Bool {
        // Regression function available
        if let regression = currentSegment.tracker.regression {
            return abs(regression.at(time) - value) <= tolerance
        }

        // Min and max guess available
        if let guesses = currentSegment.guesses {
            return self.value(value, at: time, matchesGuesses: guesses)
        }

        // Too little data points
        return true
    }

    /// Check if the data point matches the predicted next segment (using `mostRecentGuessesForNextSegment`).
    /// Call `updateNextSegmentGuesses` before calling this method.
    private func nextSegmentMatches(value: Value, at time: Time) -> Bool {
        guard let guesses = mostRecentGuessesForNextSegment else { return false }
        return self.value(value, at: time, matchesGuesses: guesses)
    }

    /// Update the guesses for the next segment.
    /// These will be used to check if a point matches the next segment, and as guesses for when the next segment is actually created.
    private func updateNextSegmentGuesses() {
        ...
    }

    /// Check if the value is either inside the two functions, or is near enough to one of the two functions (using CompositeCore's tolerance).
    private func value(_ value: Value, at time: Time, matchesGuesses guesses: Guesses) -> Bool {
        let value1 = guesses.min.at(time), value2 = guesses.max.at(time)
        let min = Swift.min(value1, value2), max = Swift.max(value1, value2)

        return (min <= value && value <= max) || abs(min - value) <= tolerance || abs(max - value) <= tolerance
    }

    /// Add one or multiple points to `allDataPoints` (just for plotting purposes).
    private func updateAllDataPoints(withSet newPoints: [DataPoint]) {
        for point in newPoints {
            allDataPoints.add(value: point.value, time: point.time, color: currentColorForPlotting)
        }
    }

    // MARK: CompositeCoreSlidingWindowDelegate

    /// New data points are available for the current segment.
    /// These definitely match the current tracker/guesses, so simply add them to the current tracker.
    func flushedDataPointsAvailableForCurrentTracker(dataPoints: [DataPoint]) {
        for point in dataPoints {
            currentSegment.tracker.add(value: point.value, at: point.time, updateRegression: false)
            allDataPoints.add(value: point.value, time: point.time, color: currentColorForPlotting)
        }
        
        currentSegment.tracker.updateRegression()
    }

    /// Actually advance to the next tracker.
    func madeDecisionToAdvanceToNextTracker(withDataPoints dataPoints: [DataPoint], discardedDataPoints: [DataPoint]) {
        // Finalize old segment
        updateAllDataPoints(withSet: discardedDataPoints)
        delegate.advancedToNextSegmentAndFinalizedLastSegment(lastSegment: currentSegment)

        // Create next segment
        let nextTracker = dataSource.trackerForNextSegment()
        dataPoints.forEach { nextTracker.add(value: $0.value, at: $0.time, updateRegression: false) }
        nextTracker.updateRegression()

        currentSegment = SegmentInfo(index: currentSegmentIndex + 1, tracker: nextTracker, guesses: mostRecentGuessesForNextSegment)
        updateAllDataPoints(withSet: dataPoints)

        delegate.currentSegmentWasUpdated(segment: currentSegment)

        // Reset guesses
        mostRecentGuessesForNextSegment = nil
    }
}
