//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// TapPredictorBase provides infrastructure for tap prediction, scheduling and locking.
open class TapPredictorBase {
    public let scheduler: TapScheduler

    /// States if the prediction lock is currently active.
    /// This will hinder tap prediction from re-calculating the tap sequence until the lock is released.
    /// The lock will be reassessed each time a new tap is performed.
    private var lockIsActive = false

    /// The tap sequence which is currently scheduled.
    private var currentSequence: TapSequence?

    /// Default initializer.
    public init(tapper: Tapper, imageProvider: ImageProvider, tapDelayTolerance: TrackerTolerance) {
        scheduler = TapScheduler(tapper: tapper, imageProvider: imageProvider, tapDelayTolerance: tapDelayTolerance)

        // Reassess lock each time a tap has been performed
        scheduler.tapPerformed.subscribe { tap in
            self.currentSequence = self.currentSequence?.afterExecuting(tap: tap)
            self.reassessLock()
        }
    }

    // MARK: Prediction Logic

    /// Call to perform a prediction step.
    /// When the lock is inactive, the predictionLogic will be executed, and its result will be scheduled.
    public func predictionStep(predictionLogic: () -> TapSequence) {
        if lockIsActive { return }

        // Perform prediction logic
        let sequence = predictionLogic()
        reschedule(sequence: sequence)

        // Reassess lock
        currentSequence = sequence
        reassessLock()
    }

    /// Reschedule a tap sequence, including its completion time for locking reassessment.
    /// Before scheduling, clear all current scheduled times.
    private func reschedule(sequence: TapSequence) {
        // First, clear current schedule
        Timing.cancelPerform(object: self)
        scheduler.clearScheduledTaps()

        // Then, schedule taps and unlock time
        sequence.taps.forEach(scheduler.schedule(tap:))

        if let unlockTime = sequence.unlockTime {
            Timing.perform(after: unlockTime, object: self) {
                self.lockIsActive = false
            }
        }
    }

    // MARK: Locking

    /// Reassess if locking should still be active.
    private func reassessLock() {
        if let sequence = currentSequence {
            lockIsActive = shouldLock(scheduledSequence: sequence)
        } else {
            lockIsActive = false
        }
    }

    /// Called each time the locking is reassessed. `scheduledSequence` contains the tap sequence which is currently scheduled, relative to the current time.
    /// Override to enable specific locking.
    open func shouldLock(scheduledSequence: TapSequence) -> Bool {
        false
    }

    // MARK: Tap Detection Forwarding

    /// Call when a tap has just been performed at the given time.
    public func tapPerformed(time: Double) {
        scheduler.delayTracker.tapPerformed(time: time)
    }

    /// Call when a tap has just been detected at the given time.
    public func tapDetected(at endTime: Double) {
        scheduler.delayTracker.tapDetected(at: endTime)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    public func refineLastTapDetectionTime(with endTime: Double) {
        scheduler.delayTracker.refineLastTapDetectionTime(with: endTime)
    }
}
