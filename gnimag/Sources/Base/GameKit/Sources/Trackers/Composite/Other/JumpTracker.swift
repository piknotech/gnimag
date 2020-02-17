//
//  Created by David Knothe on 15.10.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import TestingTools

/// JumpTracker tracks the height of an object in a physics environment with gravity.
/// It detects jumps of the object, calculating the the jump velocity and the gravity of the environment.
/// Important: This assumes that, on each jump, the object's y-velocity is set to a constant value which is NOT dependent on the previous object velocity (i.e. absolute jumping instead of relative jumping).
public final class JumpTracker: CompositeTracker<ParabolaTracker> {

    // MARK: Private Properties

    /// The constant trackers for gravity and jump velocity.
    private let gravityTracker: PreliminaryTracker
    private let jumpVelocityTracker: PreliminaryTracker

    /// The estimated gravity, if available.
    private var gravity: Value? { gravityTracker.average ?? gravityTracker.values.last }

    /// The estimated jump velocity, if available.
    /// Can be negative if time direction is inverted.
    private var jumpVelocity: Value? { jumpVelocityTracker.average ?? jumpVelocityTracker.values.last }

    /// The relative guess range for when a new jump started. Must be regular.
    /// If you know that jumps will, for example, always exactly begin at the second last data point, return [0, 0].
    private let customRelativeGuessRange: SimpleRange<Time>

    /// The constant height before the first segment started.
    /// For calculating an exact start point of the initial jump.
    private let idleHeightBeforeInitialSegment: Value?

    // MARK: Public Properties

    /// The jumping parabola, going through (0,0), if available.
    public var parabola: Parabola? {
        guard let jumpVelocity = jumpVelocity, let gravity = gravity else { return nil }
        return Parabola(a: -0.5 * gravity, b: jumpVelocity, c: 0)
    }

    /// Default initializer.
    public init(
        jumpTolerance: TrackerTolerance,
        relativeValueRangeTolerance: Value,
        consecutiveNumberOfPointsRequiredToDetectJump: Int,
        customRelativeGuessRange: SimpleRange<Time> = SimpleRange<Time>(from: 0, to: 1),
        idleHeightBeforeInitialSegment: Value? = nil
    ) {
        let tolerance = TrackerTolerance.relative(relativeValueRangeTolerance)
        gravityTracker = PreliminaryTracker(tolerancePoints: 1, tolerance: tolerance)
        jumpVelocityTracker = PreliminaryTracker(tolerancePoints: 1, tolerance: tolerance)

        self.customRelativeGuessRange = customRelativeGuessRange
        self.idleHeightBeforeInitialSegment = idleHeightBeforeInitialSegment

        let characteristics = NextSegmentDecisionCharacteristics(
            pointsMatchingNextSegment: consecutiveNumberOfPointsRequiredToDetectJump,
            maxIntermediatePointsMatchingCurrentSegment: 0
        )

        super.init(tolerance: jumpTolerance, decisionCharacteristics: characteristics)
    }

    // MARK: Delegate And DataSource

    /// A new regression for the current jump may be available.
    /// Update preliminary values for gravity and jump velocity.
    /// Return the supposed time where the segment started at.
    public override func currentSegmentWasUpdated(segment: Segment) -> Time? {
        guard let jump = segment.tracker.regression else { return nil }

        // Calculate gravity, jump velocity and jump start
        let jumpStart = calculateStartTimeForCurrentJump(currentJump: jump)
        let gravity = -2 * jump.a
        let jumpVelocity = jump.derivative.at(jumpStart)

        gravityTracker.removePreliminaryValue()
        jumpVelocityTracker.removePreliminaryValue()

        // Add preliminary values to trackers if both are valid
        if gravityTracker.isValueValid(gravity) && jumpVelocityTracker.isValueValid(jumpVelocity) {
            gravityTracker.addPreliminary(value: gravity)
            jumpVelocityTracker.addPreliminary(value: jumpVelocity)
        }

        return jumpStart
    }

    /// The current jump has finished and the next jump has begun.
    /// Finalize the gravity and jump velocity values.
    public override func willFinalizeCurrentSegmentAndAdvanceToNextSegment() {
        gravityTracker.finalizePreliminaryValue()
        jumpVelocityTracker.finalizePreliminaryValue()
    }

    /// Create a parabola tracker for the next jump segment.
    public override func trackerForNextSegment() -> ParabolaTracker {
        ParabolaTracker(tolerance: tolerance)
    }

    /// Make a guess for a jump beginning at (`time`, `value`).
    public override func guessForNextSegmentFunction(whenSplittingSegmentsAtTime time: Double, value: Double) -> Parabola? {
        guard let gravity = gravity, let jumpVelocity = jumpVelocity else { return nil }

        // Solve f(time) = value and f'(time) = jumpVelocity
        let a = -0.5 * gravity // -0.5gt^2
        let b = jumpVelocity - 2 * a * time // 2ax + b = jumpVelocity
        let c = value - (a * time * time + b * time) // ax^2 + bx + c = value

        return Parabola(a: a, b: b, c: c)
    }

    /// Provide the custom guess range.
    public override func adaptedGuessRange(for proposedGuessRange: SimpleRange<Time>) -> SimpleRange<Time> {
        let offset = proposedGuessRange.lower, size = proposedGuessRange.size

        let lower = offset + customRelativeGuessRange.lower * size
        let upper = offset + customRelativeGuessRange.upper * size
        return SimpleRange(from: lower, to: upper)
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    public override func scatterStrokable(for function: Parabola, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        QuadCurveScatterStrokable(parabola: function, drawingRange: drawingRange)
    }

    // MARK: Intersection Calculation

    /// Calculate the intersection of the last jump and the current jump.
    /// If there is no regression for the last jump, use a time between the start of the current jump and the end of the last jump.
    private func calculateStartTimeForCurrentJump(currentJump: Parabola) -> Time {
        var guess = currentSegment.tracker.times.first!

        guard let lastSegment = finalizedSegments.last else {
            // Special case: initial segment
            return calculateStartTimeForInitialSegment(currentJump: currentJump) ?? guess
        }

        // Specify guess
        if let lastJumpEndTime = lastSegment.tracker.times.last {
            guess = (guess + lastJumpEndTime) / 2
        }

        // Polynomial intersection between last and current segment
        if let lastJump = lastSegment.tracker.regression {
            let diff = currentJump - lastJump
            return QuadraticSolver.solve(diff, equals: 0, solutionNearestToGuess: guess) ?? guess
        }

        return guess
    }

    /// Special case for segment start time calculation: Calculate the start time for the initial segment using `idleHeightBeforeInitialSegment`.
    private func calculateStartTimeForInitialSegment(currentJump: Parabola) -> Time? {
        guard let idleHeight = idleHeightBeforeInitialSegment else { return nil }

        // Solve a*x^2 + b*x + c = idleHeight
        let guess = currentSegment.tracker.times.first!
        return QuadraticSolver.solve(currentJump, equals: idleHeight, solutionNearestToGuess: guess)
    }
}
