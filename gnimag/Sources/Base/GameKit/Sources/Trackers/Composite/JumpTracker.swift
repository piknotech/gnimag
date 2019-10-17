//
//  Created by David Knothe on 15.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

/// JumpTracker tracks the height of an object in a physics environment with gravity.
/// It detects jumps of the object, calculating the the jump velocity and the gravity of the environment.
/// Important: This assumes that, on each jump, the object's y-velocity is set to a constant value which is NOT dependent on the previous object velocity (i.e. absolute jumping instead of relative jumping).
public final class JumpTracker: HasScatterDataSet {
    public typealias Value = Double
    public typealias Time = Double

    // MARK: Private Properties

    private var core: CompositeCore!

    /// The constant trackers for gravity and jump velocity.
    fileprivate let gravityTracker: ConstantTracker
    fileprivate let jumpVelocityTracker: ConstantTracker

    /// The relative tolerance for the gravity and jump velocity trackers.
    /// This is used to filter out garbage values.
    fileprivate let valueRangeTolerance: Value

    /// True when values (gravity & jump velocity) from the current jump are in the trackers.
    /// Because these values are updated each frame until the jump has ended (and the next jump begins), these values are only preliminary until the jump has ended.
    fileprivate var usingPreliminaryValues = false

    /// The last jump segment.
    fileprivate var lastJump: CompositeCore.SegmentInfo?

    // MARK: Public Properties

    /// The estimated gravity, if available.
    public var gravity: Value? {
        gravityTracker.average
    }

    /// The estimated jump velocity, if available.
    public var jumpVelocity: Value? {
        jumpVelocityTracker.average
    }

    /// The data set for plotting.
    public var dataSet: [ScatterDataPoint] {
        core.allDataPoints.dataSet
    }

    // MARK: Methods

    /// Default initializer.
    public init(
        relativeValueRangeTolerance: Value,
        absoluteJumpTolerance: Value,
        consecutiveNumberOfPointsRequiredToDetectJump: Int
    ) {
        gravityTracker = ConstantTracker(tolerancePoints: 0)
        jumpVelocityTracker = ConstantTracker(tolerancePoints: 0)
        valueRangeTolerance = relativeValueRangeTolerance

        let characteristics = CompositeCore.NextSegmentDecisionCharacteristics(
            pointsMatchingNextSegment: consecutiveNumberOfPointsRequiredToDetectJump,
            maxIntermediatePointsMatchingCurrentSegment: 0
        )
        
        core = CompositeCore(tolerance: absoluteJumpTolerance, decisionCharacteristics: characteristics, delegate: self, dataSource: self)
    }
}

// MARK: Delegate

extension JumpTracker: CompositeCoreDelegate {
    /// A new regression for the current jump may be available.
    /// Update preliminary values for gravity and jump velocity.
    public func currentSegmentWasUpdated(segment: CompositeCore.SegmentInfo) {
        print("update: \(segment)")
        if let jump = segment.tracker.regression as? Polynomial {
            // Remove old preliminary values before adding new preliminary values
            if usingPreliminaryValues {
                gravityTracker.removeLast()
                jumpVelocityTracker.removeLast()
            }

            // Calculate gravity and jump velocity and jump start
            let jumpStart = calculateStartTimeForCurrentJump(currentJump: jump, currentTrackerStartTime: segment.tracker.times.first!)
            let gravity = -2 * jump.a
            let jumpVelocity = jump.derivative.at(jumpStart)

            // Add preliminary values to trackers if they are validß
            if gravityTracker.is(gravity, validWith: .relative(tolerance: valueRangeTolerance)) &&
                jumpVelocityTracker.is(jumpVelocity, validWith: .relative(tolerance: valueRangeTolerance)) {
                gravityTracker.add(value: gravity)
                jumpVelocityTracker.add(value: jumpVelocity)
                usingPreliminaryValues = true
            } else {
                usingPreliminaryValues = false
            }
        }
    }

    /// The current jump has finished and the next jump has begun.
    /// Finalize the gravity and jump velocity values.
    public func advancedToNextSegmentAndFinalizedLastSegment(lastSegment: CompositeCore.SegmentInfo) {
        // Mark the preliminary values (if existing) as final
        usingPreliminaryValues = false

        lastJump = lastSegment
    }

    /// Calculate the intersection of the last jump and the current jump.
    /// If there is no regression for the last jump, use a time between the start of the current jump and the end of the last jump.
    private func calculateStartTimeForCurrentJump(currentJump: Polynomial, currentTrackerStartTime: Time) -> Time {
        // Primitive guess
        var guess = currentTrackerStartTime
        if let lastJumpEndTime = lastJump?.tracker.times.last {
            guess = (currentTrackerStartTime + lastJumpEndTime) / 2
        }

        // Actual polynomial intersection
        if let lastJump = lastJump?.tracker.regression as? Polynomial {
            let diff = currentJump - lastJump
            guard let intersections = QuadraticSolver.solve(a: diff.a, b: diff.b, c: diff.c) else { return guess }

            // As the leading factors are probably nearly, but not exactly equal, there are two solutions, one of which is crap
            if abs(intersections.0 - guess) < abs(intersections.1 - guess) {
                return intersections.0
            } else {
                return intersections.1 // TODO: validation that intersection is nearly inside bounds?
            }
        }

        return guess
    }
}

// MARK: DataSource

extension JumpTracker: CompositeCoreDataSource {
    /// Create a parabola tracker for the next jump segment.
    public func trackerForNextSegment() -> SimpleTrackerProtocol {
        PolyTracker(degree: 2)
    }

    /// Make a guess for a jump beginning at `splitXPos`.
    public func guessForNextPartialFunction(whenSplittingSegmentsAtTime time: Double, value: Double) -> SmoothFunction? {
        guard let gravity = gravity, let jumpVelocity = jumpVelocity else { return nil }

        // Solve f(time) = value and f'(time) = jumpVelocity
        let a = -0.5 * gravity // -0.5gt^2
        let b = jumpVelocity - 2 * a * time // 2ax + b = jumpVelocity
        let c = value - (a * time * time + b * time) // ax^2 + bx + c = value

        return Polynomial([c, b, a])
    }
}
