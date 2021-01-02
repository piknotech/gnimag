//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
    public private(set) var lockIsActive = false

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
    /// When predictionLogic returns nil, nothing happens (i.e. no taps and no lock), and predictionLogic will be called again next frame.
    public func predictionStep() {
        if lockIsActive {
            frameFinished(hasPredicted: false)
            return
        }

        // Perform prediction logic. Unschedule taps beforehand to prevent taps (which would be unscheduled afterwards) from being executed during predictionLogic.
        unschedule()

        if let sequence = predictionLogic() {
            schedule(sequence: sequence)
            reassessLock()
        }

        frameFinished(hasPredicted: true)
    }

    /// Override to create a predicted tap sequence for the current frame, relative to the current frame's timepoint.
    /// When returning nil, nothing happens (i.e. no taps and no lock), and predictionLogic will be called again next frame.
    open func predictionLogic() -> RelativeTapSequence? {
        nil
    }

    /// Called after each frame, either after predictionLogic was executed (`hasPredicted = true`), or after it was not executed because the lock is active (`hasPredicted = false`).
    open func frameFinished(hasPredicted: Bool) {
    }

    /// Unschedule all scheduled taps and unlocking.
    private func unschedule() {
        scheduler.unscheduleAll()
        Timing.shared.cancelTasks(withObject: self) // Unschedule unlocking
    }

    /// Schedule a tap sequence, including its completion time for locking reassessment.
    private func schedule(sequence: RelativeTapSequence) {
        tapSequence = sequence
        referenceTimeForTapSequence = timeProvider.currentTime

        // Schedule new taps
        sequence.taps.forEach(scheduler.schedule(tap:))
    }

    // MARK: Locking

    /// Reassess if locking should still be active. Then, schedule unlocking of the lock.
    /// When the current sequence has no unlockTime, no lock will be applied.
    private func reassessLock() {
        guard let sequence = tapSequence, let unlockTime = sequence.unlockDuration else {
            lockIsActive = false
            return
        }

        lockIsActive = shouldLock(scheduledSequence: sequence)
        if lockIsActive {
            scheduleUnlocking(in: unlockTime)
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
