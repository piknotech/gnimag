//
//  Created by David Knothe on 15.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

/// JumpTracker tracks the height of an object in a physics environment with gravity.
/// It detects jumps of the object, calculating the the jump velocity and the gravity of the environment.
/// Important: This assumes that, on each jump, the object's y-velocity is set to a constant value which is NOT dependent on the previous object velocity (i.e. absolute jumping instead of relative jumping).
public final class JumpTracker: CompositeTracker<PolyTracker> {

    // MARK: Private Properties

    /// The constant trackers for gravity and jump velocity.
    private let gravityTracker: ConstantTracker
    private let jumpVelocityTracker: ConstantTracker

    /// True when values (gravity & jump velocity) from the current jump are in the trackers.
    /// Because these values are updated each frame until the jump has ended (and the next jump begins), these values are only preliminary until the jump has ended.
    private var usingPreliminaryValues = false

    /// The guess range for when a new jump started.
    /// If you know that jumps will, for example, always exactly begin at the second last data point, return [0, 0].
    private let customGuessRange: SimpleRange<Time>

    // MARK: Public Properties

    /// The estimated gravity, if available.
    public var gravity: Value? {
        gravityTracker.average ?? gravityTracker.values.last
    }

    /// The estimated jump velocity, if available.
    public var jumpVelocity: Value? {
        jumpVelocityTracker.average ?? jumpVelocityTracker.values.last
    }

    /// Default initializer.
    public init(
        relativeValueRangeTolerance: Value,
        absoluteJumpTolerance: Value,
        consecutiveNumberOfPointsRequiredToDetectJump: Int,
        customGuessRange: SimpleRange<Time> = SimpleRange<Time>(from: 0, to: 1)
    ) {
        let tolerance = TrackerTolerance.relative(relativeValueRangeTolerance)
        gravityTracker = ConstantTracker(tolerancePoints: 1, tolerance: tolerance)
        jumpVelocityTracker = ConstantTracker(tolerancePoints: 1, tolerance: tolerance)

        self.customGuessRange = customGuessRange

        let characteristics = NextSegmentDecisionCharacteristics(
            pointsMatchingNextSegment: consecutiveNumberOfPointsRequiredToDetectJump,
            maxIntermediatePointsMatchingCurrentSegment: 0
        )

        super.init(tolerance: absoluteJumpTolerance, decisionCharacteristics: characteristics)
    }

    // MARK: Delegate And DataSource

    /// A new regression for the current jump may be available.
    /// Update preliminary values for gravity and jump velocity.
    /// Return the supposed time where the segment started at.
    public override func currentSegmentWasUpdated(segment: SegmentInfo) -> Time? {
        guard let jump = segment.tracker.regression else { return nil }

        // Remove old preliminary values before adding new preliminary values
        if usingPreliminaryValues {
            gravityTracker.removeLast()
            jumpVelocityTracker.removeLast()
        }

        // Calculate gravity and jump velocity and jump start
        let jumpStart = calculateStartTimeForCurrentJump(currentJump: jump, currentTrackerStartTime: segment.tracker.times.first!)
        let gravity = -2 * jump.a
        let jumpVelocity = jump.derivative.at(jumpStart)

        // Add preliminary values to trackers if they are valid
        if gravityTracker.isValueValid(gravity) && jumpVelocityTracker.isValueValid(jumpVelocity) {
            gravityTracker.add(value: gravity)
            jumpVelocityTracker.add(value: jumpVelocity)
            usingPreliminaryValues = true
        } else {
            usingPreliminaryValues = false
        }

        return jumpStart
    }

    /// The current jump has finished and the next jump has begun.
    /// Finalize the gravity and jump velocity values.
    public override func willFinalizeCurrentSegmentAndAdvanceToNextSegment() {
        usingPreliminaryValues = false
    }

    /// Calculate the intersection of the last jump and the current jump.
    /// If there is no regression for the last jump, use a time between the start of the current jump and the end of the last jump.
    private func calculateStartTimeForCurrentJump(currentJump: Polynomial, currentTrackerStartTime: Time) -> Time {
        guard let lastSegment = finalizedSegments.last else { return currentTrackerStartTime }

        // Primitive guess
        var guess = currentTrackerStartTime
        if let lastJumpEndTime = lastSegment.tracker.times.last {
            guess = (currentTrackerStartTime + lastJumpEndTime) / 2
        }

        // Actual polynomial intersection
        if let lastJump = lastSegment.tracker.regression {
            let diff = currentJump - lastJump
            guard let intersections = QuadraticSolver.solve(a: diff.a, b: diff.b, c: diff.c) else { return guess }

            // As the leading factors are probably nearly, but not exactly equal, there are two solutions, one of which is crap
            if abs(intersections.0 - guess) < abs(intersections.1 - guess) {
                return intersections.0
            } else {
                return intersections.1
            }
        }

        return guess
    }

    /// Create a parabola tracker for the next jump segment.
    public override func trackerForNextSegment() -> PolyTracker {
        PolyTracker(degree: 2, tolerance: .absolute(tolerance))
    }

    /// Make a guess for a jump beginning at (`time`, `value`).
    public override func guessForNextPartialFunction(whenSplittingSegmentsAtTime time: Double, value: Double) -> Function? {
        guard let gravity = gravity, let jumpVelocity = jumpVelocity else { return nil }

        // Solve f(time) = value and f'(time) = jumpVelocity
        let a = -0.5 * gravity // -0.5gt^2
        let b = jumpVelocity - 2 * a * time // 2ax + b = jumpVelocity
        let c = value - (a * time * time + b * time) // ax^2 + bx + c = value

        return Polynomial([c, b, a])
    }

    /// Provide the custom guess range.
    public override func guessRange() -> SimpleRange<Time> {
        return customGuessRange
    }

    /// Return a ScatterStrokable which matches the function. For debugging.
    public override func scatterStrokable(for function: Function, drawingRange: SimpleRange<Time>) -> ScatterStrokable {
        QuadCurveScatterStrokable(parabola: function as! Polynomial, drawingRange: drawingRange)
    }
}
