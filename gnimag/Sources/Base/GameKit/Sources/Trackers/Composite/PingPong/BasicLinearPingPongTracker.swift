//
//  Created by David Knothe on 28.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import TestingTools

/// BasicLinearPingPongTracker is a PingPongTracker whose lower and upper bounds are constant, and whose segment function is linear.
public final class BasicLinearPingPongTracker: CompositeTracker<LinearTracker> {
    /// The trackers for the upper and lower bound.
    private let lowerBoundTracker: PreliminaryTracker
    private let upperBoundTracker: PreliminaryTracker

    /// The tracker for the slope. The slope is always positive.
    private let slopeTracker: PreliminaryTracker

    public var slope: Value? { slopeTracker.average.map(abs) }
    public var lowerBound: Value? { lowerBoundTracker.average.map(abs) }
    public var upperBound: Value? { upperBoundTracker.average.map(abs) }

    internal enum Direction {
        case up
        case down

        var reversed: Direction {
            switch self {
            case .up: return .down
            case .down: return .up
            }
        }
    }

    /// The direction of the very first segment (with index 0).
    private var firstSegmentDirection: Direction?

    /// The direction of any given segment.
    /// An "up" direction means that the values are approaching the upper bound, irregardless of the time direction.
    /// This means that, when time is inverted, the segment slope is negative, even though direction is "up".
    internal func direction(for index: Int) -> Direction? {
        index.isMultiple(of: 2) ? firstSegmentDirection : firstSegmentDirection?.reversed
    }

    /// Default initializer.
    public init(
        tolerance: TrackerTolerance,
        slopeTolerance: TrackerTolerance,
        boundsTolerance: TrackerTolerance,
        decisionCharacteristics: NextSegmentDecisionCharacteristics
    ) {
        lowerBoundTracker = PreliminaryTracker(tolerancePoints: 0, tolerance: boundsTolerance)
        upperBoundTracker = PreliminaryTracker(tolerancePoints: 0, tolerance: boundsTolerance)
        slopeTracker = PreliminaryTracker(tolerancePoints: 0, tolerance: slopeTolerance)

        super.init(tolerance: tolerance, decisionCharacteristics: decisionCharacteristics)
    }

    // MARK: Delegate And DataSource

    /// A new regression for the current segment may be available.
    /// Update the preliminary value for the slope.
    /// Return the supposed time where the segment started at.
    public override func currentSegmentWasUpdated(segment: Segment) -> Time? {
        guard let line = segment.tracker.regression else { return nil }
        guard monotonicityChecker.direction != .both else { return nil }

        // 1.: Determine the direction if it is unknown
        if firstSegmentDirection == nil {
            let approachingUpperBound = (line.slope > 0) == (monotonicityChecker.direction == .increasing)
            let isEvenSegment = currentSegment.index.isMultiple(of: 2)
            firstSegmentDirection = (approachingUpperBound == isEvenSegment) ? .up : .down
        }
        let currentDirection = direction(for: currentSegment.index)

        // 2.: Update slope tracker
        // Add the positive slope to the tracker. Do NOT use abs(slope) because, for slopes near 0, this could distort the average slope value. This means, "positiveSlope" could also be negative if the data points are widely scattered.
        let positiveSlope = (currentDirection == .up) ? +line.slope : -line.slope

        // Update preliminary slope if valid
        slopeTracker.updatePreliminaryValueIfValid(value: positiveSlope)

        // 3.: Update lower or upper bound tracker
        guard
            let lastLine = finalizedSegments.last?.tracker.regression,
            let intersectionX = LinearSolver.zero(of: line - lastLine) else { return nil }

        let intersectionY = line.at(intersectionX)

        let relevantTracker = (currentDirection == .up) ? lowerBoundTracker : upperBoundTracker

        // Update preliminary bound if valid
        relevantTracker.updatePreliminaryValueIfValid(value: intersectionY)

        return intersectionX
    }

    /// The current segment has finished and the next segment has begun.
    /// Finalize the value for the slope.
    public override func willFinalizeCurrentSegmentAndAdvanceToNextSegment() {
        // Mark the preliminary values (if existing) as final
        lowerBoundTracker.finalizePreliminaryValue()
        upperBoundTracker.finalizePreliminaryValue()
        slopeTracker.finalizePreliminaryValue()
    }

    /// Create a linear tracker for the next segment.
    public override func trackerForNextSegment() -> LinearTracker {
        LinearTracker(tolerancePoints: 3, tolerance: tolerance)
    }

    /// Make a guess for a segment beginning at (`time`, `value`).
    public override func guessForNextSegmentFunction(whenSplittingSegmentsAtTime time: Time, value: Value) -> LinearFunction? {
        guard
            let direction = direction(for: currentSegment.index),
            let positiveSlope = slopeTracker.average else { return nil }

        // Construct f = ax+b with f(time) = value
        let slope = (direction == .up) ? -positiveSlope : +positiveSlope
        let intercept = value - slope * time

        return LinearFunction(slope: slope, intercept: intercept)
    }

    /// Move the guess range back to compensate for a possibly too large tolerance (i.e. a very late segment switch detection).
    public override func guessRange(for timeRange: Time, midpoint: Time) -> SimpleRange<Time> {
        guard let slope = slopeTracker.average else {
            return SimpleRange(from: 0, to: 0.5)
        }

        // The vertical tolerance at the critical point
        let verticalTolerance: Double

        switch tolerance {
        case let .absolute(tolerance):
            verticalTolerance = tolerance

        case let .absolute2D(dy: dy, dx: dx):
            // Calculate the tangent point of the ellipse with a line with the regression's slope.
            // Then, go downwards until hitting the actual regression line (going through (0, 0)).
            let x = dx * sqrt(pow(slope, 2) / (pow(dy/dx, 2) + pow(slope, 2)))
            let y = sqrt(pow(dy, 2) - pow(x * dy/dx, 2)) // (x, y) is the tangent point on the ellipse
            verticalTolerance = y + abs(slope) * x

        case let .relative(tolerance):
            guard let f = currentSegment.tracker.regression else { return SimpleRange(from: 0, to: 0.5) }
            verticalTolerance = abs(tolerance * f.at(midpoint))
        }

        // d: horizontal distance from tolerance line to actual line
        let d = verticalTolerance / abs(slope)
        let from = 0.5 - d / (2 * timeRange) // Go d/2 back in time, starting at 0.5 (midpoint between a and b)
        let to = 0.5 // Range cannot start after the midpoint of a and b

        return SimpleRange(from: from, to: to)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    public override func scatterStrokable(for function: LinearFunction, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        LinearScatterStrokable(line: function, drawingRange: drawingRange)
    }
}
