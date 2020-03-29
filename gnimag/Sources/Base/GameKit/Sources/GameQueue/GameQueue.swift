//
//  Created by David Knothe on 30.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Dispatch
import Foundation
import Image

public final class GameQueue {
    public typealias Frame = ImageProvider.Frame

    /// The timing stats which give you information about frame durations, frame dismissal rates and more.
    public let timingStats: GameQueueTimingStats

    private let imageProvider: ImageProvider

    /// High-priority queue where frame analysis is performed.
    private let queue: DispatchQueue

    /// The callback which is executed in the background to analyze frames.
    /// Only return from this callback after you finished analyzing the frame.
    private let synchronousFrameCallback: (Frame) -> Void

    /// States if `performCurrentTasksInQueue` is currently executed.
    private var isSpawningTasks = false

    /// The next frame that will be analyzed, assumed that no new frame comes in while waiting for the current frame to finish analysis.
    private var nextFrameToAnalyze: Frame?

    /// Default initializer.
    public init(imageProvider: ImageProvider, synchronousFrameCallback: @escaping (Frame) -> Void) {
        self.imageProvider = imageProvider
        self.synchronousFrameCallback = synchronousFrameCallback
        self.queue = DispatchQueue(label: "GameQueue", qos: .userInteractive) // High-priority queue
        self.timingStats = GameQueueTimingStats(timeProvider: imageProvider.timeProvider)
    }

    /// Begin receiving images.
    public func begin() {
        imageProvider.newFrame += self • newFrame
    }

    /// Stop receiving images.
    public func stop() {
        imageProvider.newFrame.unsubscribe(self)
    }

    /// This method schedules frame analysis in the background.
    /// This method is called from the `imageProvider` event thread / queue.
    private func newFrame(frame: Frame) {
        synchronized(self) {
            timingStats.newFrame(frame: frame)

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
