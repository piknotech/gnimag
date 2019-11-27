//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

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
        fileprivate var supposedStartTime: Time

        fileprivate var colorForPlotting: ScatterColor {
            index.isMultiple(of: 2) ? .even : .odd
        }
    }

    /// Guesses are used for two things:
    /// - Checking if a point is valid in the current segment, when the current segment has no regression yet
    /// - Checking if a point is valid in the next segment (as the next segment cannot have a regression before it is created)
    public struct Guesses {
        let a: Function
        let b: Function? // If the two guesses are the same, one of them is omitted.

        var all: [Function] { [a, b].compactMap(id) }

        // The start times of the respective guesses. For debugging.
        fileprivate var aXStart: Time
        fileprivate var bXStart: Time?
        fileprivate var allStartTimes: [Time] { [aXStart, bXStart].compactMap(id) }
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
    private var mostRecentGuessesForNextSegment: Guesses?

    /// The absolute tolerance for all segments/trackers.
    public let tolerance: Double

    /// A dataset with all data points (including invalid ones which have been checked in `is(value:validAt:)`, for plotting with ScatterPlot.
    public private(set) var allDataPoints = SimpleDataSet()
    public var dataSet: [ScatterDataPoint] { allDataPoints.dataSet }

    /// Create information about regression functions from each segment.
    /// Attention: this is a possibly expensive operation.
    public var allFunctionInfos: [FunctionDebugInfo] {
        var result = [FunctionDebugInfo]()
        let all = finalizedSegments + [currentSegment!]

        /// Convenience function to add a ScatterStrokable for a given function to the result.
        func add(_ function: Function, with color: ScatterColor, from startTime: Time, to endTime: Time) {
            let range = SimpleRange(from: startTime, to: endTime, enforceRegularity: true)
            let strokable = scatterStrokable(for: function, color: color, drawingRange: range)
            result.append(FunctionDebugInfo(function: function, strokable: strokable))
        }

        // Add ScatterStrokables for each segment
        for (i, segment) in all.enumerated() {
            let endTime = (i < all.count - 1) ? all[i+1].supposedStartTime : timeInfinity
            let color = segment.colorForPlotting

            // Regression function
            if let function = segment.tracker.regression {
                add(function, with: color, from: segment.supposedStartTime, to: endTime)
            }

            // Guesses
            else if let guesses = segment.guesses {
                for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                    add(function, with: color, from: startTime, to: endTime)
                }
            }
        }

        // Guesses for next segment
        if let guesses = mostRecentGuessesForNextSegment {
            let color = currentSegment.colorForPlotting == .even ? ScatterColor.odd : .even
            for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                add(function, with: color, from: startTime, to: timeInfinity)
            }
        }

        return result
    }

    /// A monotonicity checker which enforces that values are only added in a time-monontone order.
    private let monotonicityChecker = MonotonicityChecker<Time>(direction: .both, strict: true)

    /// The most distant value for time.
    /// Because time direction can either be increasing or decreasing, this is either + or -infinity.
    private var timeInfinity: Time {
        monotonicityChecker.direction == .decreasing ? -.infinity : +.infinity
    }
    
    /// Default initializer.
    public init(tolerance: Double, decisionCharacteristics: NextSegmentDecisionCharacteristics) {
        self.tolerance = tolerance
        self.window = CompositeTrackerSlidingWindow(characteristics: decisionCharacteristics)

        // Create initial tracker
        let tracker = trackerForNextSegment()
        currentSegment = SegmentInfo(index: 0, tracker: tracker, guesses: nil, supposedStartTime: -timeInfinity)

        window.delegate = self
    }

    // MARK: Public Methods

    /// Check if a point is valid to be added to the tracker.
    /// Call this before actually calling `add(value:at:)`.
    public func integrityCheck(with value: Value, at time: Time) -> Bool {
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
        if currentSegment.tracker.hasRegression {
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
        let range = guessRange()
        let minTime = timeA + (timeB - timeA) * range.lower
        let maxTime = timeA + (timeB - timeA) * range.upper // maxTime is more recent than minTime
        let timeslots = minTime == maxTime ? [minTime] : [minTime, maxTime]

        // Use either the regression or the guesses of the current segment
        var functions: [Function]

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
    private func createGuesses(forFunctions functions: [Function], andTimeslots timeslots: [Time], mostRecentTime: Time) -> Guesses? {
        if functions.isEmpty || timeslots.isEmpty { return nil }

        typealias GuessAndTime = (guess: Function, time: Time)

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
            return Guesses(a: min.guess, b: nil, aXStart: min.time, bXStart: nil)
        } else {
            return Guesses(a: min.guess, b: max.guess, aXStart: min.time, bXStart: max.time)
        }
    }

    /// Check if the value is either inside the two functions, or is near enough to one of the two functions (using CompositeTracker's tolerance).
    private func value(_ value: Value, at time: Time, matchesGuesses guesses: Guesses) -> Bool {
        let values = guesses.all.map { $0.at(time) }
        let min = values.min()!, max = values.max()!

        return (min <= value && value <= max) || abs(min - value) <= tolerance || abs(max - value) <= tolerance
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
        let nextTracker = trackerForNextSegment()
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

    // MARK: - Delegate And DataSource

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
    /// For the tolerance value, use `.absolute(tolerance)`.
    /// This will be called **after** `willFinalizeCurrentSegmentAndAdvanceToNextSegment` is called on the delegate.
    open func trackerForNextSegment() -> SegmentTrackerType {
        fatalError("Override and implement this method.")
    }

    /// Make a guess for the next partial function which begins at the given split position.
    /// If you don't have enough information for making the guess, return nil.
    open func guessForNextPartialFunction(whenSplittingSegmentsAtTime time: Double, value: Double) -> Function? {
        fatalError("Override and implement this method.")
    }

    /// Return the range that defines where the two guesses (min and max guess) should be made.
    /// The interval is transformed so that [0, 1] maps to [timeA, timeB] where timeA is the second last time and timeB the most recent time.
    /// You can, for example, return [0, 0] if you are sure that the segment certainly started at the second last data point. You can also return negative values – times will then be extended further in the past.
    /// Important: The range must be valid, i.e. the max value must be greater than the min value.
    /// Also, values above 1 do not make sense because they would represent a timepoint in the future.
    open func guessRange() -> SimpleRange<Time> {
        SimpleRange<Time>(from: 0, to: 1)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    /// The function is either a regression function from one of the trackers, or a guess.
    /// This means, the function was provided by you, and you can be certain about its specific type.
    open func scatterStrokable(for function: Function, color: ScatterColor, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        fatalError("Override and implement this method.")
    }
}
