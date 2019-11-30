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

    private let imageProvider: ImageProvider

    /// High-priority queue where frame analysis is performed.
    private let queue: DispatchQueue

    /// The callback which is executed in the background to analyze frames.
    /// Only return from this callback after you finished analyzing the frame.
    private let synchronousFrameCallback: (Frame) -> Void

    /// States if an image is currently being analyzed.
    private var isBusy = false

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

    /// This method schedules frame analysis in the background or marks the current frame as waiting.
    private func newFrame(frame: Frame) {
        synchronized(self) {
            if isBusy {
                mostRecentWaitingFrame = frame
            } else {
                // Perform analysis on background game queue
                isBusy = true
                queue.async {
                    self.synchronousFrameCallback(frame)
                    self.analyzeWaitingFrame()
                }
            }
        }
    }

    /// Analyze (synchronously) the most recent waiting frame, if existing.
    /// This method is called on the background game queue.
    private func analyzeWaitingFrame() {
        // Fetch and clear `mostRecentWaitingFrame` synchronously
        if let frame = (synchronized(self) { () -> Frame? in
            defer { mostRecentWaitingFrame = nil }
            return mostRecentWaitingFrame
        }) {
            synchronousFrameCallback(frame) // Synchronous
        }

        isBusy = false
    }
}
