//
//  Created by David Knothe on 07.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

public extension BasicLinearPingPongTracker {
    /// A portion of (or a full) segment of the linear ping pong tracker.
    struct LinearSegmentPortion {
        /// The index of the future portion in the composite tracker.
        public let index: Int

        /// The time range of the segment portion.
        /// This range is always regular, regardless of the time direction.
        public let timeRange: SimpleRange<Time>

        /// The line.
        public let line: LinearFunction

        /// Default initializer.
        public init(index: Int, timeRange: SimpleRange<Time>, line: LinearFunction) {
            self.index = index
            self.timeRange = timeRange
            self.line = line
        }
    }

    /// States if all conditions are met so that `segmentPortionsForFutureTimeRange` will not return an optional value.
    func segmentPortionsForFutureTimeRangeAvailable(guesses: (lowerBound: Double, upperBound: Double)) -> Bool {
        requiredProperties(guesses: guesses) != nil
    }

    /// Calculate the segment portions that will be passed during a given time range in the future.
    /// When time is inverted, the time range should also be inverted, i.e. `lower > upper`.
    /// The range must not be singular!
    /// `guesses` provides guesses for the tracker's lower and upper bounds when they are not yet determined.
    func segmentPortionsForFutureTimeRange(_ timeRange: SimpleRange<Time>, guesses: (lowerBound: Double, upperBound: Double)) -> [LinearSegmentPortion]? {
        guard let properties = requiredProperties(guesses: guesses) else { return nil }

        // The index of a segment that contains a given time value.
        func indexForSegment(atTime time: Time) -> Int {
            let timeShift = (time - properties.startingPoint.startTime)
            let indexShift = Double(properties.timeDirection) * timeShift / properties.segmentDuration // >= 0 (when time is in the future)

            let startingIndex = properties.startingPoint.segment.index
            return Int(floor(indexShift)) + startingIndex
        }

        // Calculate begin and end segment indices (with end > begin)
        let beginIndex = indexForSegment(atTime: timeRange.lower)
        let endIndex = indexForSegment(atTime: timeRange.upper)

        // Calculate LinearSegmentPortion for each partial or full segment
        return (beginIndex ... endIndex).compactMap { index in
            segmentPortion(index: index, maximalTimeRange: timeRange, properties: properties)
        }
    }

    // MARK: Required Properties

    /// Properties which are all required (i.e. non-nil) for further calculations.
    private struct RequiredProperties {
        let slope: Double
        let lowerBound: Double
        let upperBound: Double
        let segmentDuration: Time

        /// The direction time is running in. Either +1 or -1.
        let timeDirection: Int

        /// A segment, together with a non-nil starting time and direction value, based on which the future calculations will be executed.
        let startingPoint: StartingPointForFutureCalculations

        struct StartingPointForFutureCalculations {
            let segment: Segment
            let startTime: Time
            let direction: Direction
        }
    }

    /// Fetch all required properties for calculation.
    private func requiredProperties(guesses: (lowerBound: Double, upperBound: Double)) -> RequiredProperties? {
        // Get required (non-nil) properties
        guard let slope = slope else { return nil }
        let lowerBound = self.lowerBound ?? guesses.lowerBound
        let upperBound = self.upperBound ?? guesses.upperBound

        // Calculate the duration each segment takes
        let segmentDuration = (upperBound - lowerBound) / slope

        // Get starting point and time direction
        guard let startingPoint = startingPoint(lowerBound: lowerBound, upperBound: upperBound),
            let timeDirection = monotonicityChecker.direction.intValue else { return nil }

        // Collect everything
        return RequiredProperties(slope: slope, lowerBound: lowerBound, upperBound: upperBound, segmentDuration: segmentDuration, timeDirection: timeDirection, startingPoint: startingPoint)
    }

    /// Create a starting point for the following calculations; i.e. find the last useful segment.
    private func startingPoint(lowerBound: Double, upperBound: Double) -> RequiredProperties.StartingPointForFutureCalculations? {
        let allSegments = finalizedSegments + [currentSegment!]

        // Try finding a good segment with a start time
        var goodSegment: Segment?
        var supposedStartTime: Double?

        // Plan A: use latest segment which has an actual supposedStartTime
        if let segment = (allSegments.last { $0.supposedStartTime != nil }) {
            goodSegment = segment
            supposedStartTime = segment.supposedStartTime!
        }

        // Plan B: use last segment with regression and approximate the start time by intersecting with the upper or lower bound
        else if let lastSegment = (allSegments.last { $0.tracker.hasRegression }), let direction = direction(for: lastSegment.index), let line = lastSegment.tracker.regression {
            // Solve line(x) = upperBound (or lowerBound)
            let bound = (direction == .up) ? lowerBound : upperBound

            if let startTime = LinearSolver.zero(of: line + (-bound)) {
                goodSegment = lastSegment
                supposedStartTime = startTime
            }
        }

        guard let segment = goodSegment, let startTime = supposedStartTime, let direction = direction(for: segment.index) else { return nil }

        return RequiredProperties.StartingPointForFutureCalculations(segment: segment, startTime: startTime, direction: direction)
    }

    // MARK: Future Segments

    /// Calculate a LinearSegmentPortion for a future segment with the given index.
    /// The full segment time range will be intersected with `maximalTimeRange`, which possibly creates a segment portion (instead of a full segment).
    private func segmentPortion(index: Int, maximalTimeRange: SimpleRange<Time>, properties: RequiredProperties) -> LinearSegmentPortion? {
        // Intersect regularized time ranges
        let regularTimeRange = segmentTimeRange(index: index, properties: properties).regularized
        let regularMaximalRange = maximalTimeRange.regularized
        var intersection = regularTimeRange.intersection(with: regularMaximalRange)
        if intersection.isSinglePoint { return nil }

        // De-regularize range, if required, to go back to the original range direction
        if properties.timeDirection < 0 {
            intersection = SimpleRange(from: intersection.upper, to: intersection.lower)
        }

        // Calculate segment function
        let function = segmentFunction(index: index, properties: properties)
        return LinearSegmentPortion(index: index, timeRange: intersection, line: function)
    }

    /// Calculate the linear function for a future segment with the given index.
    private func segmentFunction(index: Int, properties: RequiredProperties) -> LinearFunction {
        let timeRange = segmentTimeRange(index: index, properties: properties)
        let startTime = timeRange.lower
        let startValue = (direction(for: index) == .up) ? properties.lowerBound : properties.upperBound

        // Calculate segment function
        let sign = Double(properties.timeDirection) * (direction(for: index) == .up ? +1 : -1)
        let slope = sign * properties.slope
        let intercept = startValue - slope * startTime

        return LinearFunction(slope: slope, intercept: intercept)
    }

    /// Calculate the time range a future segment will have.
    /// Thereby, lower is the start time and upper the end time of the segment. This means, the range is not necessarily regular.
    private func segmentTimeRange(index: Int, properties: RequiredProperties) -> SimpleRange<Time> {
        let indexDiff = index - properties.startingPoint.segment.index
        let startTime = properties.startingPoint.startTime + Double(indexDiff) * properties.segmentDuration * Double(properties.timeDirection)
        let endTime = startTime + properties.segmentDuration * Double(properties.timeDirection)

        return SimpleRange(from: startTime, to: endTime)
    }
}
