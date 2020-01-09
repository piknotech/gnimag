//
//  Created by David Knothe on 07.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

public extension BasicLinearPingPongTracker {
    /// A portion of (or a full) segment of the linear ping pong tracker.
    struct LinearSegmentPortion {
        /// The index of the future portion in the composite tracker.
        let index: Int

        /// The time range of the segment portion.
        /// This range is always regular, regardless of the time direction.
        let timeRange: SimpleRange<Time>

        /// The linear function.
        let function: Polynomial
    }

    /// Calculate the segment portions that will be passed during a given time range in the future.
    /// When time is inverted, the time range should also be inverted, i.e. `lower > upper`.
    func segmentPortionsForFutureTimeRange(_ timeRange: SimpleRange<Time>) -> [LinearSegmentPortion]? {
        guard let properties = requiredProperties() else { return nil }

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
    private func requiredProperties() -> RequiredProperties? {
        // Get required (non-nil) properties
        guard let lowerBound = lowerBoundTracker.average else { return nil } // TODO: GUESSES
        guard let upperBound = upperBoundTracker.average else { return nil }
        guard let slope = slope else { return nil }

        // Calculate the duration each segment takes.
        let segmentDuration = (upperBound - lowerBound) / slope

        // Create starting point for future calculations
        let allSegments = [currentSegment!] + finalizedSegments.reversed()

        guard
            let goodSegment = (allSegments.first { $0.supposedStartTime != nil }),
            let direction = direction(for: goodSegment.index) else { return nil }

        let startingPoint = RequiredProperties.StartingPointForFutureCalculations(segment: goodSegment, startTime: goodSegment.supposedStartTime!, direction: direction)

        // Get time direction
        guard let timeDirection = monotonicityChecker.direction.intValue else { return nil }

        // Collect everything
        return RequiredProperties(slope: slope, lowerBound: lowerBound, upperBound: upperBound, segmentDuration: segmentDuration, timeDirection: timeDirection, startingPoint: startingPoint)
    }

    // MARK: Future Segments

    /// Calculate a LinearSegmentPortion for a future segment with the given index.
    /// The full segment time range will be intersected with `maximalTimeRange`, which possibly creates a segment portion (instead of a full segment).
    private func segmentPortion(index: Int, maximalTimeRange: SimpleRange<Time>, properties: RequiredProperties) -> LinearSegmentPortion? {
        // Intersect regularized time ranges
        let regularTimeRange = segmentTimeRange(index: index, properties: properties).regularized
        let regularMaximalRange = maximalTimeRange.regularized
        let intersection = regularTimeRange.intersection(with: regularMaximalRange)
        if intersection.isSinglePoint { return nil }

        // Calculate segment function
        let function = segmentFunction(index: index, properties: properties)
        return LinearSegmentPortion(index: index, timeRange: intersection, function: function)
    }

    /// Calculate the linear function for a future segment with the given index.
    private func segmentFunction(index: Int, properties: RequiredProperties) -> Polynomial {
        let timeRange = segmentTimeRange(index: index, properties: properties)
        let startTime = timeRange.lower
        let startValue = (direction(for: index) == .up) ? properties.lowerBound : properties.upperBound

        // Calculate segment function
        let slope = (direction(for: index) == .up) ? +properties.slope : -properties.slope
        let intercept = startValue - slope * startTime

        return Polynomial([intercept, slope])
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
