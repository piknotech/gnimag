//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Image
import Tapping

/// TapPredictorBase provides infrastructure for tap prediction, locking and sequence scheduling.
open class TapPredictorBase {
    public let timeProvider: TimeProvider
    public let scheduler: TapScheduler

    /// States if the prediction lock is currently active.
    /// This will hinder tap prediction from re-calculating the tap sequence until the lock is released.
    /// The lock will be reassessed each time a new tap is performed.
    private var lockIsActive = false

    /// The currently scheduled tap sequence, consisting of all future taps.
    /// Performed taps will be removed from this sequence.
    public private(set) var tapSequence: RelativeTapSequence?
    public private(set) var referenceTimeForTapSequence: Double?

    /// Default initializer.
    public init(tapper: SomewhereTapper, timeProvider: TimeProvider, tapDelayTolerance: TrackerTolerance) {
        self.timeProvider = timeProvider
        scheduler = TapScheduler(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: tapDelayTolerance)

        // Reassess lock each time a tap has been performed
        scheduler.tapPerformed.subscribe { tap in
            self.tapSequence?.remove(tap: tap.scheduledTap.relativeTap)
            self.reassessLock()
        }
    }

    /// Perform a tap at the current moment.
    public func tapNow() {
        scheduler.tapNow()
    }

    // MARK: Prediction Logic

    /// Call to perform a prediction step.
    /// When the lock is inactive, the predictionLogic will be executed, and its result will be scheduled. The sequence must only contain tap values in the future!
    /// When predictionLogic returns nil, the current sequence is performed further (and not updated).
    public func predict() {
        if lockIsActive {
            noPredictionBecauseLockIsActive()
            return
        }

        // Perform prediction logic
        if let sequence = predictionLogic() {
            reschedule(sequence: sequence)
            reassessLock()
        }
    }

    /// Override to create a predicted tap sequence for the current frame, relative to the current frame's timepoint.
    /// When returning nil, the current sequence is left unchanged.
    open func predictionLogic() -> RelativeTapSequence? {
        nil
    }

    /// Called to inform subclasses that no prediction will be performed this frame because a lock is currently active.
    open func noPredictionBecauseLockIsActive() {
    }

    /// Reschedule a tap sequence, including its completion time for locking reassessment.
    /// Before scheduling, clear all current scheduled taps.
    private func reschedule(sequence: RelativeTapSequence) {
        tapSequence = sequence
        referenceTimeForTapSequence = timeProvider.currentTime

        // Clear current schedule
        scheduler.unscheduleAll()
        unscheduleUnlocking()

        // Schedule new taps and unlocking
        sequence.taps.forEach(scheduler.schedule(tap:))

        if let unlockDuration = sequence.unlockDuration {
            scheduleUnlocking(in: unlockDuration)
        }
    }

    /// Schedule unlocking in a given time interval.
    private func scheduleUnlocking(in distance: Double) {
        Timing.shared.perform(after: distance, identification: .object(self)) {
            self.tapSequence = nil
            self.referenceTimeForTapSequence = nil
            self.lockIsActive = false
        }
    }

    /// Unschedule the scheduled unlocking.
    private func unscheduleUnlocking() {
        Timing.shared.cancelTasks(withObject: self)
    }

    // MARK: Locking

    /// Reassess if locking should still be active.
    private func reassessLock() {
        if let sequence = tapSequence {
            lockIsActive = shouldLock(scheduledSequence: sequence)
        } else {
            lockIsActive = false
        }
    }

    /// Called each time the locking is reassessed. `scheduledSequence` contains the tap sequence which is currently scheduled, relative to the current time.
    /// Override to enable specific locking.
    open func shouldLock(scheduledSequence: RelativeTapSequence) -> Bool {
        false
    }

    // MARK: Tap Detection Forwarding

    /// Call when a tap has just been detected at the given time.
    public func tapDetected(at endTime: Double) {
        scheduler.delayTracker.tapDetected(at: endTime)
    }

    /// Call when the tap detection time of the latest tap has been updated.
    public func refineLastTapDetectionTime(with endTime: Double) {
        scheduler.delayTracker.refineLastTapDetectionTime(with: endTime)
    }
}
