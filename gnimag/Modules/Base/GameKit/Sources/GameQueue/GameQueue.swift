//
//  Created by David Knothe on 30.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Dispatch
import Foundation
import Image

public final class GameQueue {
    public typealias Frame = ImageProvider.Frame

    /// The timing stats which give you information about frame durations, frame dismissal rates and more.
    public let timingStats: GameQueueTimingStats

    /// More sophisticated detector regarding exact frame durations.
    /// Must explicitly be provided during initialization.
    private let framerateDetector: FramerateDetector?

    private let imageProvider: ImageProvider

    /// High-priority queue where frame analysis and further calculation is performed on.
    private let queue = DispatchQueue(label: "gnimag.gamequeue", qos: .userInteractive)

    /// The callback which is executed in the background to analyze frames.
    /// Only return from this callback after you finished analyzing the frame.
    private let synchronousFrameCallback: (Frame) -> Void

    /// States if `performCurrentTasksInQueue` is currently executed.
    private var isSpawningTasks = false

    /// The next frame that will be analyzed, assumed that no new frame comes in while waiting for the current frame to finish analysis.
    private var nextFrameToAnalyze: Frame?

    /// Default initializer.
    public init(imageProvider: ImageProvider, synchronousFrameCallback: @escaping (Frame) -> Void, framerateDetector: FramerateDetector? = nil) {
        self.imageProvider = imageProvider
        self.synchronousFrameCallback = synchronousFrameCallback
        self.timingStats = GameQueueTimingStats(timeProvider: imageProvider.timeProvider)
        self.framerateDetector = framerateDetector
    }

    /// Begin receiving images.
    public func begin() {
        imageProvider.newFrame += self • newFrame
    }

    /// Stop receiving images.
    public func stop() {
        imageProvider.newFrame.unsubscribe(self)
        clear()
    }

    /// Convenience method to stop the queue for a given time, then restart it.
    /// If the queue is not running yet, it will be started after the given time.
    public func stop(for duration: Double) {
        stop()

        // Cancel previous `stop(for:)` tasks as the most recent one overrides the previous ones
        let identification = Timing.Identification.object(self, string: "stop(for:)")
        Timing.shared.cancelTasks(matching: identification)
        Timing.shared.perform(after: duration, identification: identification, block: begin)
    }

    /// Remove frames which are currently in waiting state.
    /// This ensures that the next incoming frame is from the future.
    public func clear() {
        synchronized(self) {
            nextFrameToAnalyze = nil
        }
    }

    /// This method schedules frame analysis in the background.
    /// This method is called from the `imageProvider` event thread / queue.
    private func newFrame(frame: Frame) {
        let incomingTime = imageProvider.timeProvider.currentTime

        synchronized(self) {
            framerateDetector?.newFrame(time: frame.1)
            timingStats.newFrame(frame: frame, at: incomingTime)

            // Note if the previous frame was dropped
            if nextFrameToAnalyze != nil { timingStats.frameDropped() }

            // Note if the current frame has to wait
            if isSpawningTasks { timingStats.frameCannotImmediatelyBeAnalyzed() }

            // Schedule frame, either for immediate or later processing
            nextFrameToAnalyze = frame
            queue.async(execute: performCurrentTasksInQueue)
        }
    }

    /// Analyze (synchronously, on the background queue) the most recent waiting frame, if existing.
    /// After analyzing the current frame, analyze the next one, if existing, and so on.
    /// This method is always called on the background game queue, and without an active lock.
    private func performCurrentTasksInQueue() {
        // Only allow one access to this method at once. If there is already a frame being analyzed, leave
        let shouldContinue = synchronized(self) { () -> Bool in
            if isSpawningTasks { return false }
            isSpawningTasks = true
            return true
        }

        // If there is already a frame being analyzed, leave
        guard shouldContinue else { return }

        // Next-frame-analysis loop
        while true {
            // Fetch and clear `mostRecentWaitingFrame` synchronized
            if let frame = (synchronized(self) { () -> Frame? in
                defer { nextFrameToAnalyze = nil }
                return nextFrameToAnalyze
            }) {
                // Analyze frame synchronously on the queue.
                // Of course, there exists NO lock during this execution
                timingStats.currentFrameAnalysisStarted()
                synchronousFrameCallback(frame)
                timingStats.currentFrameAnalysisEnded()
            } else {
                // No image is waiting; leave this method. Nothing happens until the next comes in
                synchronized(self) { isSpawningTasks = false }
                break
            }
        }
    }
}
