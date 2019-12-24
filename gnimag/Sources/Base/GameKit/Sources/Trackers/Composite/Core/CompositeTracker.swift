//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// CompositeTracker defines an abstract class providing basic required functionalities for a composite tracker; that is, a tracker which tracks a piecewise defined funtion.
/// When you inherit from CompositTracker, you must implement a handful of Delegate and DataSource methods.
open class CompositeTracker<SegmentTrackerType: SimpleTrackerProtocol>: CompositeTrackerSlidingWindowDelegate, HasScatterDataSet {
    public typealias Time = Double
    public typealias Value = Double

    // MARK: Subtypes
    
    /// Chracteristics which describe how and when to make a segment advancement decision.
    public struct NextSegmentDecisionCharacteristics {
        /// The number of points which must match the next segment.
        /// Must be positive.
        /// When this is 1, `maxIntermediatePointsMatchingCurrentSegment` is irrelevant, as there are no intermediate points.
        let pointsMatchingNextSegment: Int

        /// During the interval in which `pointsMatchingNextSegment` points matching the next segment are collected, at most `maxIntermediatePointsMatchingCurrentSegment` are allowed to match the current, old segment.
        /// Can be zero.
        /// If more points match the current segment, the decision action is (partially) cancelled.
        let maxIntermediatePointsMatchingCurrentSegment: Int

        /// Default initializer.
        public init(pointsMatchingNextSegment: Int, maxIntermediatePointsMatchingCurrentSegment: Int) {
            self.pointsMatchingNextSegment = pointsMatchingNextSegment
            self.maxIntermediatePointsMatchingCurrentSegment = maxIntermediatePointsMatchingCurrentSegment
        }
    }

    /// Information about a segment, either the current segment or a previous one.
    public struct SegmentInfo {
        public let index: Int
        public let tracker: SegmentTrackerType

        /// When the tracker has no regression yet, use the guesses (which come from the last segment) for approximated functions and values.
        public let guesses: Guesses?

        /// The time where the segment has supposedly started. For debugging.
        internal var supposedStartTime: Time

        internal var colorForPlotting: ScatterColor {
            index.isMultiple(of: 2) ? .even : .odd
        }
    }

    /// Guesses are used for two things:
    /// - Checking if a point is valid in the current segment, when the current segment has no regression yet
    /// - Checking if a point is valid in the next segment (as the next segment cannot have a regression before it is created)
    public struct Guesses {
        /// The guesses. At least one guess is guaranteed.
        public let all: [SegmentTrackerType.F]

        /// The start times of the respective guesses. For debugging.
        internal let allStartTimes: [Time]

        /// Default initializer.
        fileprivate init(a:SegmentTrackerType.F, b: SegmentTrackerType.F? = nil, aXStart: Time, bXStart: Time? = nil) {
            all = [a, b].compactMap(id)
            allStartTimes = [aXStart, bXStart].compactMap(id)
        }
    }

    // MARK: Properties

    /// The sliding window where data points are forwarded to.
    /// The points are then received via delegate callbacks.
    private let window: CompositeTrackerSlidingWindow<SegmentTrackerType>

    /// All segments prior to the current segments.
    public private(set) var finalizedSegments = [SegmentInfo]()

    /// Up-to-date information about the current segment.
    public private(set) var currentSegment: SegmentInfo!

    /// The most recent guesses that have been made for the next segment. When the next segment is actually created, these guesses are used.
    internal var mostRecentGuessesForNextSegment: Guesses?

    /// The tolerance for all trackers (including segment trackers and guesses).
    public let tolerance: TrackerTolerance

    /// This dataset contains both valid and invalid points (but no points that are currently in the decision window)
    private var allDataPoints = SimpleDataSet()

    /// The tolerance region info from the last data point, applied on the current tracker.
    /// Nil if the current tracker has no regression.
    public private(set) var lastToleranceRegionScatterStrokable: ScatterStrokable?

    /// The full dataset, containing all points:
    ///  - Valid points that have been added to the tracker,
    ///  - Invalid points that failed the `integrityCheck`,
    ///  - Points that are currently in the decision window and therefore propably belong to the next segment.
    public var dataSet: [ScatterDataPoint] {
        allDataPoints.dataSet +
        window.dataPoints.map { ScatterDataPoint(x: $0.time, y: $0.value, color: .inDecisionWindow) }
    }

    /// A monotonicity checker which enforces that values are only added in a time-monontone order.
    private let monotonicityChecker = MonotonicityChecker<Time>(direction: .both, strict: true)

    /// The most distant value for time.
    /// Because time direction can either be increasing or decreasing, this is either + or -infinity.
    internal var timeInfinity: Time {
        monotonicityChecker.direction == .decreasing ? -.infinity : +.infinity
    }
    
    /// Default initializer.
    public init(tolerance: TrackerTolerance, decisionCharacteristics: NextSegmentDecisionCharacteristics) {
        self.tolerance = tolerance
        self.window = CompositeTrackerSlidingWindow(characteristics: decisionCharacteristics)

        // Create initial tracker
        var tracker = trackerForNextSegment()
        tracker.tolerance = tolerance
        currentSegment = SegmentInfo(index: 0, tracker: tracker, guesses: nil, supposedStartTime: -timeInfinity)

        window.delegate = self
    }

    // MARK: Public Methods

    /// Check if a point is valid to be added to the tracker.
    /// Call this before actually calling `add(value:at:)`.
    public func integrityCheck(with value: Value, at time: Time) -> Bool {
        lastToleranceRegionScatterStrokable = nil // Reset debug info; will be set in `currentSegmentMatches`

        if !monotonicityChecker.verify(value: time) { print("not monotone! – \(time)"); return false }

        if currentSegmentMatches(value: value, at: time) { return true }
        if nextSegmentMatches(value: value, at: time) { return true }

        // Value is invalid – still add to `allDataPoints` for plotting
        allDataPoints.add(value: value, time: time, color: .invalid)
        return false
    }

    /// Add a data point to the tracker if it is valid.
    /// You MUST call `integrityCheck` before calling this method.
    public func add(value: Value, at time: Time) {
        // Add to current segment, if matching
        if currentSegmentMatches(value: value, at: time) {
            window.addDataPoint(value: value, time: time, matching: .current)
        }

        // Add to next segment, if matching
        else if nextSegmentMatches(value: value, at: time) {
            window.addDataPoint(value: value, time: time, matching: .next)
        }
    }

    // MARK: Private Methods

    /// Check if the data point matches the current segment regression.
    private func currentSegmentMatches(value: Value, at time: Time) -> Bool {
        // Regression function available
        if let regression = currentSegment.tracker.regression {
            lastToleranceRegionScatterStrokable = currentSegment.tracker.scatterStrokable(forToleranceRangeAroundTime: time, value: value, f: regression)
            return currentSegment.tracker.isDataPointValid(value: value, time: time, fallback: .valid)
        }

        // Min and max guess available
        if let guesses = currentSegment.guesses {
            return self.value(value, at: time, matchesGuesses: guesses)
        }

        // Too little data points
        return true
    }

    /// Check if the data point matches the predicted next segment (using `mostRecentGuessesForNextSegment`).
    /// NOTE: This method calls `updateNextSegmentGuesses` to refresh the guesses before checking for a match.
    private func nextSegmentMatches(value: Value, at time: Time) -> Bool {
        updateNextSegmentGuesses(forNextDataPoint: (time: time, value: value))
        guard let guesses = mostRecentGuessesForNextSegment else { return false }
        return self.value(value, at: time, matchesGuesses: guesses)
    }

    /// Update the guesses for the next segment.
    /// These will be used to check if a point matches the next segment, and as guesses for when the next segment is actually created.
    private func updateNextSegmentGuesses(forNextDataPoint nextDataPoint: (time: Time, value: Value)) {
        mostRecentGuessesForNextSegment = nil

        // Determine the timeslot in which the next segment could have started.
        // If there is currently a decision running, the timeslot is independent of the current data point; else, it is between the last and the current data point.
        guard let timeA = currentSegment.tracker.times.last else { return }
        let timeB = window.decisionInitiator?.time ?? nextDataPoint.time // timeB is more recent than timeA

        // Transform timeslots to match the custom guess range
        let range = guessRange(for: abs(timeB - timeA), midpoint: (timeA + timeB) / 2)
        let minTime = timeA + (timeB - timeA) * range.lower
        let maxTime = timeA + (timeB - timeA) * range.upper // maxTime is more recent than minTime
        let timeslots = minTime == maxTime ? [minTime] : [minTime, maxTime]

        // Use either the regression or the guesses of the current segment
        var functions: [SegmentTrackerType.F]

        if let regression = currentSegment.tracker.regression {
            functions = [regression]
        } else if let guesses = currentSegment.guesses {
            functions = guesses.all
        } else {
            return // No regression and no guesses – can only happen for the very first tracker
        }

        mostRecentGuessesForNextSegment =
            createGuesses(forFunctions: functions, andTimeslots: timeslots, mostRecentTime: maxTime)
    }

    /// Create enclosing (min & max) guesses from the given parameters:
    ///  - functions: The functions that enclose the target function. This can either be the target function itself, or guesses for it.
    ///  - timeslots: The timeslots for each of which a guess should be made. The resulting function will be compared by their value at the most recent time.
    ///  - mostRecentTime: The most recent time from `timeslots`. This can either be the smallest or largest time, depending on the direction time is running in.
    private func createGuesses(forFunctions functions: [SegmentTrackerType.F], andTimeslots timeslots: [Time], mostRecentTime: Time) -> Guesses? {
        if functions.isEmpty || timeslots.isEmpty { return nil }

        typealias GuessAndTime = (guess: SegmentTrackerType.F, time: Time)

        // Create a guess for each function/time combination
        let guesses: [GuessAndTime] = (functions × timeslots).compactMap { function, time in
            guessForNextPartialFunction(whenSplittingSegmentsAtTime: time, value: function.at(time)).map {
                ($0, time) // (guess, time) tuple, or nil if guess = nil
            }
        }

        if guesses.count == 0 { return nil }

        // Sort by comparing the value at the most recent time
        let comparator: (GuessAndTime, GuessAndTime) -> Bool = { guess1, guess2 in
            guess1.guess.at(mostRecentTime) < guess2.guess.at(mostRecentTime)
        }

        let min = guesses.min(by: comparator)!, max = guesses.max(by: comparator)!

        // Explicitly leave "b" empty if both guesses are identical (because the guess range is empty).
        // This is good for debugging to avoid drawing the exact same function twice.
        if guesses.count == 1 {
            return Guesses(a: min.guess, aXStart: min.time)
        } else {
            return Guesses(a: min.guess, b: max.guess, aXStart: min.time, bXStart: max.time)
        }
    }

    /// Check if the value is either inside the two functions, or is near enough to one of the two functions (using `self.tolerance`).
    private func value(_ value: Value, at time: Time, matchesGuesses guesses: Guesses) -> Bool {
        let values = guesses.all.map { $0.at(time) }
        let min = values.min()!, max = values.max()!

        // Check if y-value is inside bounds defined by guesses
        if min <= value && value <= max { return true }

        // Do normal tolerance checks with all guesses
        return guesses.all.any {
            AnyFunctionToleranceChecker(function: $0, tolerance: tolerance).isDataPointValid(value: value, time: time)
        }
    }

    /// Add one or multiple points to `allDataPoints` (just for plotting purposes).
    private func updateAllDataPoints(withSet newPoints: [DataPoint]) {
        for point in newPoints {
            allDataPoints.add(value: point.value, time: point.time, color: currentSegment.colorForPlotting)
        }
    }

    /// Update `supposedXRange` of the current segment.
    /// `currentSegmentStartTime` is the time value that was returned by the `currentSegmentWasUpdated` delegate call.
    private func updateCurrentStartTime(with startTime: Time?) {
        currentSegment.supposedStartTime = startTime ?? -timeInfinity
    }

    // MARK: CompositeTrackerSlidingWindowDelegate

    /// New data points are available for the current segment.
    /// These definitely match the current tracker/guesses, so simply add them to the current tracker.
    func flushedDataPointsAvailableForCurrentTracker(dataPoints: [DataPoint]) {
        for point in dataPoints {
            currentSegment.tracker.add(value: point.value, at: point.time, updateRegression: false)
            allDataPoints.add(value: point.value, time: point.time, color: currentSegment.colorForPlotting)
        }
        
        currentSegment.tracker.updateRegression()
        let time = currentSegmentWasUpdated(segment: currentSegment)
        updateCurrentStartTime(with: time)
    }

    /// Actually advance to the next tracker.
    func madeDecisionToAdvanceToNextTracker(withDataPoints dataPoints: [DataPoint], discardedDataPoints: [DataPoint]) {
        // Finalize old segment
        updateAllDataPoints(withSet: discardedDataPoints)
        willFinalizeCurrentSegmentAndAdvanceToNextSegment()
        finalizedSegments.append(currentSegment)

        // Create next segment
        var nextTracker = trackerForNextSegment()
        nextTracker.tolerance = tolerance
        dataPoints.forEach { nextTracker.add(value: $0.value, at: $0.time, updateRegression: false) }
        nextTracker.updateRegression()

        currentSegment = SegmentInfo(
            index: currentSegment.index + 1,
            tracker: nextTracker,
            guesses: mostRecentGuessesForNextSegment,
            supposedStartTime: dataPoints.first!.time // Time of the least recent data point in the new tracker
        )

        updateAllDataPoints(withSet: dataPoints)
        let time = currentSegmentWasUpdated(segment: currentSegment)
        updateCurrentStartTime(with: time)

        // Reset guesses
        mostRecentGuessesForNextSegment = nil
    }

    // MARK: Abstract Methods (Delegate And DataSource)

    /// Called each time the regression function or the guesses of the current segment are updated, i.e. each time a new point is added to the current segment.
    /// This is called at least once per segment.
    /// Return the supposed time where the segment started at.
    open func currentSegmentWasUpdated(segment: SegmentInfo) -> Time? {
        fatalError("Override and implement this method.")
    }

    /// Called when the current segment is being finalized and focus moves to the next segment.
    /// The segment does not necessarily have a regression function, but it has at least a regression function or guesses.
    /// Called exactly once per segment.
    open func willFinalizeCurrentSegmentAndAdvanceToNextSegment() {
        fatalError("Override and implement this method.")
    }

    /// Called exactly once per segment to create an appropriate empty tracker for the next partial function.
    /// You do not need to set a tolerance value, as it will be overridden with `self.tolerance`.
    /// This will be called **after** `willFinalizeCurrentSegmentAndAdvanceToNextSegment` is called on the delegate.
    open func trackerForNextSegment() -> SegmentTrackerType {
        fatalError("Override and implement this method.")
    }

    /// Make a guess for the next partial function which begins at the given split position.
    /// If you don't have enough information for making the guess, return nil.
    open func guessForNextPartialFunction(whenSplittingSegmentsAtTime time: Double, value: Double) -> SegmentTrackerType.F? {
        fatalError("Override and implement this method.")
    }

    /// Return the range that defines where the two guesses (min and max guess) should be made.
    /// The interval is transformed so that [0, 1] maps to [timeA, timeB] where timeA is the second last time and timeB the most recent time.
    /// You can, for example, return [0, 0] if you are sure that the segment certainly started at the second last data point. You can also return negative values – times will then be extended further in the past.
    /// Important: The range must be valid, i.e. the max value must be greater than the min value.
    /// Also, values above 1 do not make sense because they would represent a timepoint in the future.
    /// `timeRange: timeB - timeA`; `timeRange > 0`.
    open func guessRange(for timeRange: Time, midpoint: Time) -> SimpleRange<Time> {
        SimpleRange<Time>(from: 0, to: 1)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    /// The function is either a regression function from one of the trackers, or a guess.
    open func scatterStrokable(for function: SegmentTrackerType.F, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        fatalError("Override and implement this method.")
    }
}
