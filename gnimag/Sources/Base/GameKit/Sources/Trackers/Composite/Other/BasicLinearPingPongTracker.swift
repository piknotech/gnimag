//
//  Created by David Knothe on 28.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
    public var lowerBound: Value? { lowerBoundTracker.average }
    public var upperBound: Value? { upperBoundTracker.average }

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

    /// The bound direction of any given segment.
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

        // 1.: Determine the direction if it is unknown, or anytime during the first segment
        if firstSegmentDirection == nil || currentSegment.index == 0 {
            let approachingUpperBound = (line.slope > 0) == (monotonicityChecker.direction == .increasing)
            let isEvenSegment = currentSegment.index.isMultiple(of: 2)
            firstSegmentDirection = (approachingUpperBound == isEvenSegment) ? .up : .down
        }

        // 2.: Update slope tracker (with absolute slope value)
        slopeTracker.updatePreliminaryValueIfValid(value: abs(line.slope))

        // 3.: Update lower or upper bound tracker
        guard
            let lastLine = finalizedSegments.last?.tracker.regression,
            let intersectionX = LinearSolver.zero(of: line - lastLine) else { return nil }

        let currentDirection = direction(for: currentSegment.index)
        let relevantTracker = (currentDirection == .up) ? lowerBoundTracker : upperBoundTracker

        // Update preliminary bound if valid
        let intersectionY = line.at(intersectionX)
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
            let direction = direction(for: currentSegment.index + 1),
            let timeDirection = monotonicityChecker.direction.intValue,
            let absoluteSlope = slope else { return nil }

        let slopeSign = Double(timeDirection) * (direction == .up ? +1 : -1)

        // Construct f = ax+b with f(time) = value
        let slope = slopeSign * absoluteSlope
        let intercept = value - slope * time

        return LinearFunction(slope: slope, intercept: intercept)
    }

    /// Extend the guess range to compensate for a possibly too small tolerance (i.e. a very late segment switch detection).
    public override func adaptedGuessRange(for proposedGuessRange: SimpleRange<Time>) -> SimpleRange<Time> {
        guard let slope = self.slope else { return proposedGuessRange }

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
            verticalTolerance = y + slope * x

        case let .relative(tolerance):
            guard let f = currentSegment.tracker.regression else { return proposedGuessRange }
            let maxAbsoluteValue = max(abs(f.at(proposedGuessRange.lower)), abs(f.at(proposedGuessRange.upper)))
            verticalTolerance = abs(tolerance * maxAbsoluteValue)
        }
        
        // delta: horizontal distance from tolerance line to actual line
        let delta = verticalTolerance / (2 * slope)
        let timeDirectionSign = Double(monotonicityChecker.direction.intValue ?? 0)
        return SimpleRange(from: proposedGuessRange.lower - timeDirectionSign * delta, to: proposedGuessRange.upper)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    public override func scatterStrokable(for function: LinearFunction, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        LinearScatterStrokable(line: function, drawingRange: drawingRange)
    }
}
