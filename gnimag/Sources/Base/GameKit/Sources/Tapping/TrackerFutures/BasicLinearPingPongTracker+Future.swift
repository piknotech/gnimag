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
        let timeRange: SimpleRange<Time>

        /// The linear function.
        let function: Polynomial
    }

    /// Calculate the segment portions that will be passed during a given time range in the future.
    func segmentPortionsForFutureTimeRange(_ timeRange: SimpleRange<Time>) -> [LinearSegmentPortion]? {
        guard let properties = requiredProperties() else { return nil }

        // Calculate begin and end segment indices
        let indexOffset = properties.startingPoint.segment.index
        let beginShift = timeRange.lower - properties.startingPoint.startTime
        let beginIndex = Int(floor(beginShift / properties.segmentDuration)) + indexOffset
        let endShift = timeRange.upper - properties.startingPoint.startTime
        let endIndex = Int(floor(endShift / properties.segmentDuration)) + indexOffset

        // Calculate LinearSegmentPortion for each partial or full segment
        return (beginIndex ... endIndex).compactMap { index in
            segmentPortion(index: index, maximalTimeRange: timeRange, properties: properties)
        }
    }

    // MARK: Required Properties

    /// Properties which are all required (non-nil) for successful calculations.
    private struct RequiredProperties {
        let startingPoint: StartingPointForFutureCalculations
        let slope: Double
        let lowerBound: Double
        let upperBound: Double
        let segmentDuration: Time // Can be negative (when time direction is inverted)

        /// A segment, together with a non-nil starting time and direction value, based on which the future calculations will be executed.
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
        // This can be negative (if time direction is inverted).
        let segmentDuration = (upperBound - lowerBound) / slope

        // Create starting point for future calculations
        let allSegments = [currentSegment!] + finalizedSegments.reversed()

        guard
            let goodSegment = (allSegments.first { $0.supposedStartTime != nil }),
            let direction = direction(for: goodSegment.index) else { return nil }

        let startingPoint = RequiredProperties.StartingPointForFutureCalculations(segment: goodSegment, startTime: goodSegment.supposedStartTime!, direction: direction)

        // Collect everything
        return RequiredProperties(startingPoint: startingPoint, slope: slope, lowerBound: lowerBound, upperBound: upperBound, segmentDuration: segmentDuration)
    }

    // MARK: Future Segments

    /// Calculate a LinearSegmentPortion for a future segment with the given index.
    /// The full segment time range will be intersected with `maximalTimeRange`, which possibly creates a segment portion (instead of a full segment).
    private func segmentPortion(index: Int, maximalTimeRange: SimpleRange<Time>, properties: RequiredProperties) -> LinearSegmentPortion? {
        let timeRange = segmentTimeRange(index: index, properties: properties).intersection(with: maximalTimeRange)
        if timeRange.isEmpty { return nil }

        let function = segmentFunction(index: index, properties: properties)
        return LinearSegmentPortion(index: index, timeRange: timeRange, function: function)
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
    private func segmentTimeRange(index: Int, properties: RequiredProperties) -> SimpleRange<Time> {
        let indexDiff = index - properties.startingPoint.segment.index
        let startTime = properties.startingPoint.startTime + Double(indexDiff) * properties.segmentDuration
        let endTime = startTime + properties.segmentDuration

        return SimpleRange(from: startTime, to: endTime)
    }
}
