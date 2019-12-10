//
//  Created by David Knothe on 30.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Dispatch
import Foundation
import Image

public final class GameQueue {
    public typealias Frame = (Image, Double)

    /// The timing stats which give you information about frame durations, frame dismissal rates and more.
    public let timingStats = GameQueueTimingStats()

    private let imageProvider: ImageProvider

    /// High-priority queue where frame analysis is performed.
    private let queue: DispatchQueue

    /// The callback which is executed in the background to analyze frames.
    /// Only return from this callback after you finished analyzing the frame.
    private let synchronousFrameCallback: (Frame) -> Void

    /// States if `performCurrentTasksInQueue` is currently executed.
    private var isSpawningTasks = false

    /// When a new frame comes in while the queue is busy, the last frame is stored to be analyzed once self is not busy anymore.
    private var mostRecentWaitingFrame: Frame?

    /// Default initializer.
    public init(imageProvider: ImageProvider, synchronousFrameCallback: @escaping (Frame) -> Void) {
        self.imageProvider = imageProvider
        self.synchronousFrameCallback = synchronousFrameCallback
        self.queue = DispatchQueue(label: "GameQueue", qos: .userInteractive) // High-priority queue
    }

    /// Begin receiving images.
    public func begin() {
        imageProvider.newImage += newFrame
    }

    /// Stop receiving images.
    /// Attention: this removes all subscribers from the image provider.
    public func stop() {
        imageProvider.newImage.unsubscribeAll()
    }

    /// This method schedules frame analysis in the background.
    /// This method is called from the `imageProvider` event thread / queue.
    private func newFrame(frame: Frame) {
        synchronized(self) {
            mostRecentWaitingFrame = frame
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
                defer { mostRecentWaitingFrame = nil }
                return mostRecentWaitingFrame
            }) {
                // Analyze frame synchronously on queue
                synchronousFrameCallback(frame)
            } else {
                // No image is waiting; leave this method. Nothing happens until the next comes in
                synchronized(self) { isSpawningTasks = false }
                break
            }
        }
    }
}
