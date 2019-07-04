//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// JumpTracker tracks the height of an object in a physics environment with gravity.
/// It detects jumps of the object, calculating the the jump velocity and the gravity of the environment.

public final class JumpTracker {
    public typealias Value = Double
    public typealias Time = Double
    
    /// The internal tracker for the data points.
    /// It always consists of only the current jump; if a new jump is detected, the old jump data is removed.
    private let tracker: PolyTracker
    
    /// The tracker used to calculate the average gravity value.
    private let gravityTracker: ConstantTracker
    
    /// The tracker used to calculate the average jump velocity.
    private let jumpVelocityTracker: ConstantTracker
    
    /// The relative tolerance for the gravity and jump velocity trackers.
    /// This is used to filter out garbage values.
    private let valueRangeTolerance: Value
    
    /// The absolute tolerance for jumps detected by the internal data point tracker.
    /// This is absolute because the values may come close to zero or change their sign.
    private let jumpTolerance: Value
    
    /// Default initializer.
    public init(maxDataPoints: Int = 200, valueRangeTolerance: Value, jumpTolerance: Value) {
        tracker = PolyTracker(maxDataPoints: maxDataPoints, degree: 2)
        gravityTracker = ConstantTracker(maxDataPoints: maxDataPoints)
        jumpVelocityTracker = ConstantTracker(maxDataPoints: maxDataPoints)
        self.valueRangeTolerance = valueRangeTolerance
        self.jumpTolerance = jumpTolerance
    }
    
    // MARK: - Jump tracking
    
    /// The parabola of the last jump.
    private var lastParabola: Polynomial<Double>?
    
    /// The parabola of the current jump.
    private var currentParabola: Polynomial<Double>? {
        return tracker.regression
    }
    
    /// The last updated time value.
    private var lastTime: Time!
    
    /// The time range in which the current jump started.
    private var currentJumpStartBounds: (Time, Time)!
    
    /// States if the preliminary gravity and jump velocity estimations using the current parabola are currently added to the trackers.
    /// This can change multiple times during a jump.
    private var currentEstimationsAreInTheTrackers = false
    
    /// The preliminary values for the first jump, where the trackers have no definite values yet.
    private var firstJumpPreliminaryValues: (gravity: Value, jumpVelocity: Value)!
    
    // MARK: - Adding data points
    
    /// Add a data point to the tracker.
    /// This automatically updates the underlying trackers.
    public func add(value: Value, at time: Time) {
        // The tracking always starts with a jump -> set jump start value on very first call
        currentJumpStartBounds = currentJumpStartBounds ?? (time, time)
        
        // Check if parabola for current jump exists
        if let currentJump = currentParabola { // -> tracker.hasRegression
            let (gravity, jumpVelocity) = (-2 * currentJump.a, currentJump.derivative.at(currentJumpStart))
            
            // Data point is inside - jump is continued
            if tracker.is(value, at: time, validWith: .absolute(tolerance: jumpTolerance)) {
                tracker.add(value: value, at: time)
                
                // Preliminary update: last jump exists
                if lastParabola != nil {
                    performUpdate(withGravity: gravity, jumpVelocity: jumpVelocity, isPreliminary: true, isFirstJump: false)
                }
                
                // Preliminary update: we are in the first jump and already have a preliminary estimation
                else if currentEstimationsAreInTheTrackers {
                    performUpdate(withGravity: gravity, jumpVelocity: jumpVelocity, isPreliminary: true, isFirstJump: true)
                }
                
                // We are inside the first jump without preliminary estimation
                else {
                    // Check if the values are in a good range; if yes, begin preliminary estimation using the trackers
                    if let values = firstJumpPreliminaryValues {
                        let gravityValid = gravity > 0 && abs(values.gravity - gravity) <= values.gravity * valueRangeTolerance * 0.5 // Stricter tolerance
                        let jumpValid = jumpVelocity > 0 && abs(values.jumpVelocity - jumpVelocity) <= values.jumpVelocity * valueRangeTolerance * 0.5
                        
                        if gravityValid && jumpValid {
                            // Add preliminary values
                            gravityTracker.add(value: gravity)
                            jumpVelocityTracker.add(value: jumpVelocity)
                            currentEstimationsAreInTheTrackers = true
                        }
                        
                        // Update estimation if range doesn't fit
                        else {
                            firstJumpPreliminaryValues = (gravity, jumpVelocity)
                        }
                    }
                    
                    // Set values on first call
                    else {
                        firstJumpPreliminaryValues = (gravity, jumpVelocity)
                    }
                }
            }
            
            // Data point is outside - new jump has begun
            else {
                // Definite update
                let isFirstJump = (lastParabola == nil)
                performUpdate(withGravity: gravity, jumpVelocity: jumpVelocity, isPreliminary: false, isFirstJump: isFirstJump)
                
                // Reset and prepare for next jump
                lastParabola = currentParabola
                currentJumpStartBounds = (lastTime, time)
                tracker.clear()
                tracker.add(value: value, at: time)
            }
        }
        
        // Parabola does not exist yet, just add data point
        else {
            tracker.add(value: value, at: time)
        }
        
        lastTime = time
    }
    
    /// Calculate the intersection point of the current and the last jump, and clamp it to "currentJumpStartBounds".
    private var currentJumpStart: Time {
        let bounds = currentJumpStartBounds!
        
        // First jump: return first call time
        guard let current = currentParabola, let last = lastParabola else {
            return bounds.0
        }
        
        // The start point of the interval often is a good approximation for the intersection point
        let noIntersection = bounds.0
        
        // Clamp a value to bounds
        let clamp: (Double) -> Double = { return min(max($0, bounds.0), bounds.1) }
        
        // Linear equation if quadratic factor is identical
        if abs(current.a - last.a) <= 1e-5 {
            let slope = current.b - last.b
            let intercept = current.c - last.c
            
            // No solution when slopes are identical
            return slope == 0 ? noIntersection : clamp(-intercept / slope)
        }
        
        // Quadratic equation
        else {
            let p = (current.b - last.b) / (current.a - last.a)
            let q = (current.c - last.c) / (current.a - last.a)
            
            // No solution
            if (p/2) * (p/2) < q {
                return noIntersection
            }
            
            // P/q formula
            let root = ((p/2) * (p/2) - q).squareRoot()
            let x1 = -p/2 + root
            let x2 = -p/2 - root
            
            // Take the value where the distance to the further bound point is smallest.
            // This always favors points inside the bounds, and if both are outside, gets the nearest one.
            let dist1 = max(abs(x1 - bounds.0), abs(x1 - bounds.1))
            let dist2 = max(abs(x2 - bounds.0), abs(x2 - bounds.1))
            
            return dist1 < dist2 ? clamp(x1) : clamp(x2)
        }
    }
    
    /// Perform an update; either preliminary (during a jump), or definite (after a jump).
    /// The gravity and jump velocity trackers must already have an average value.
    private func performUpdate(withGravity gravity: Value, jumpVelocity: Value, isPreliminary: Bool, isFirstJump: Bool) {
        // Remove old preliminary values
        if currentEstimationsAreInTheTrackers {
            gravityTracker.removeLast()
            jumpVelocityTracker.removeLast()
        }
        
        // Check if values are in a good range (or if we are in the first jump, then each value is valid)
        let gravityValid = isFirstJump || gravityTracker.is(gravity, validWith: .relative(tolerance: valueRangeTolerance))
        let jumpValid = isFirstJump || jumpVelocityTracker.is(jumpVelocity, validWith: .relative(tolerance: valueRangeTolerance))
        
        // Update values if required
        if gravityValid && jumpValid {
            gravityTracker.add(value: gravity)
            jumpVelocityTracker.add(value: jumpVelocity)
            currentEstimationsAreInTheTrackers = isPreliminary // On a definite update, the updated values cannot be removed later on
        }
        else {
            currentEstimationsAreInTheTrackers = false
        }
    }
    
    // MARK: - Retrieving physics values
    
    /// The gravity value of the environment.
    /// Nil if not enough data points are available.
    public var gravity: Value? {
        gravityTracker.average
    }
    
    /// The jump velocity of the object.
    /// Nil if not enough data points are available.
    public var jumpVelocity: Value? {
        jumpVelocityTracker.average
    }
}
