//
//  Created by David Knothe on 28.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// BasicLinearPingPongTracker is a PingPongTracker whose lower and upper bounds are constant, and whose segment function is linear.
public final class BasicLinearPingPongTracker: CompositeTracker<LinearTracker> {
    /// The trackers for the upper and lower bound.
    public let lowerBoundTracker: ConstantTracker
    public let upperBoundTracker: ConstantTracker

    /// The tracker for the slope. The slope which is being added here is always positive (i.e. for the "up" direction)
    /// There is one tolerance point because the first value is often too imprecise.
    public let slopeTracker: ConstantTracker

    /// States if a preliminary value for the slope / for the upper/lower bound is in the respective tracker.
    private var preliminarySlopeIsInTracker = false
    private var preliminaryBoundIsInTracker = false

    private enum Direction {
        case up
        case down
    }
    private var currentDirection: Direction!

    /// Default initializer.
    public init(
        absoluteSegmentSwitchTolerance: Value,
        slopeTolerance: TrackerTolerance,
        boundsTolerance: TrackerTolerance,
        decisionCharacteristics: NextSegmentDecisionCharacteristics
    ) {
        lowerBoundTracker = ConstantTracker(tolerancePoints: 0, tolerance: boundsTolerance)
        upperBoundTracker = ConstantTracker(tolerancePoints: 0, tolerance: boundsTolerance)
        slopeTracker = ConstantTracker(tolerancePoints: 1, tolerance: slopeTolerance)

        super.init(tolerance: absoluteSegmentSwitchTolerance, decisionCharacteristics: decisionCharacteristics)
    }

    // MARK: Delegate And DataSource

    /// A new regression for the current segment may be available.
    /// Update the preliminary value for the slope.
    /// Return the supposed time where the segment started at.
    public override func currentSegmentWasUpdated(segment: SegmentInfo) -> Time? {
        guard let slope = segment.tracker.slope, let intercept = segment.tracker.intercept else { return nil }

        // 1.: Determine the direction if it is unknown
        if currentDirection == nil {
            currentDirection = (slope > 0) ? .up : .down
        }

        // 2.: Update slope tracker
        // Add the positive slope to the tracker. Do NOT use abs(slope) because, for slopes near 0, this could distort the average slope value. This means, "positiveSlope" could also be negative if the data points are widely scattered.
        let positiveSlope = (currentDirection == .up) ? +slope : -slope

        // Update preliminary slope if valid
        if preliminarySlopeIsInTracker { slopeTracker.removeLast() }
        preliminarySlopeIsInTracker = slopeTracker.isValueValid(positiveSlope)
        if preliminarySlopeIsInTracker { slopeTracker.add(value: positiveSlope) }

        // 3.: Update lower or upper bound tracker
        guard
            let lastSegment = finalizedSegments.last,
            let lastSlope = lastSegment.tracker.slope,
            let lastIntercept = lastSegment.tracker.intercept,
            let intersectionX = LinearSolver.solve(slope: slope - lastSlope, intercept: intercept - lastIntercept) else { return nil }

        let intersectionY = slope * intersectionX + intercept

        let relevantTracker = (currentDirection == .up) ? lowerBoundTracker : upperBoundTracker

        // Update preliminary bound if valid
        if preliminaryBoundIsInTracker { relevantTracker.removeLast() }
        preliminaryBoundIsInTracker = relevantTracker.isValueValid(intersectionY)
        if preliminaryBoundIsInTracker { relevantTracker.add(value: intersectionY) }

        return intersectionX
    }

    /// The current segment has finished and the next segment has begun.
    /// Finalize the value for the slope.
    public override func willFinalizeCurrentSegmentAndAdvanceToNextSegment() {
        currentDirection = (currentDirection == .up) ? .down : .up

        // Mark the preliminary values (if existing) as final
        preliminarySlopeIsInTracker = false
        preliminaryBoundIsInTracker = false
    }

    /// Create a linear tracker for the next segment.
    public override func trackerForNextSegment() -> LinearTracker {
        LinearTracker(tolerancePoints: 3, tolerance: .absolute(tolerance))
    }

    /// Make a guess for a segment beginning at (`time`, `value`).
    public override func guessForNextPartialFunction(whenSplittingSegmentsAtTime time: Time, value: Value) -> Function? {
        guard
            let direction = currentDirection,
            let positiveSlope = slopeTracker.average ?? slopeTracker.values.last else { return nil }

        // Construct f = ax+b with f(time) = value
        let slope = (direction == .up) ? -positiveSlope : +positiveSlope
        let intercept = value - slope * time

        return Polynomial([intercept, slope])
    }

    /// Move the guess range to the back to
    public override func guessRange(for timeRange: Time) -> SimpleRange<Time> {
        guard let slope = slopeTracker.average ?? slopeTracker.values.last else {
            return SimpleRange(from: 0, to: 0.5)
        }

        // d: horizontal distance from tolerance line to actual line (tolerance is the vertical distance)
        let d = tolerance / abs(slope)
        let from = 0.5 - d / (2 * timeRange) // Go d/2 back in time, starting at 0.5 (midpoint between a and b)
        let to = 0.5 // Range cannot start after the midpoint of a and b
        return SimpleRange(from: from, to: to)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    public override func scatterStrokable(for function: Function, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        LinearScatterStrokable(line: function as! Polynomial, drawingRange: drawingRange)
    }
}
