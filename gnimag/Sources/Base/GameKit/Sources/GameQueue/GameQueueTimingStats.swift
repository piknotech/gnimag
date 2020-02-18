//
//  Created by David Knothe on 30.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Image

public final class GameQueueTimingStats {
    private let timeProvider: TimeProvider

    /// Default initializer.
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    /// The average total duration of a frame (1/framerate).
    public let frameDuration = ConstantTracker(tolerancePoints: 0)

    /// The average duration to perform image copy/preparation tasks.
    /// This refers to image prepration done by the image provider itself (e.g. creating a NativeImage).
    public let imageCopyDuration = ConstantTracker(tolerancePoints: 0)

    /// The average duration of frame analysis which is performed by your specific game. This does not include the image copy duration.
    public let analysisDuration = ConstantTracker(tolerancePoints: 0)

    /// The total number of frames.
    public private(set) var totalFrames = 0

    /// The number of frames which could not be immediately analzed because the queue was busy while they came in.
    /// This INCLUDES all dismissed frames, as they also fall in this category.
    public private(set) var waitingFrames = 0

    /// The number of frames which were not analyzed.
    /// This does NOT include frames which were put in waiting state, but analyzed thereafter.
    /// This means, `dismissedFrames <= waitingFrames`.
    public private(set) var dismissedFrames = 0

    /// Set to `true` to pause timing stats tracking.
    /// Useful when, for example, the game is in a paused / non-analysis state and you don't want that state to manipulate the timing stats.
    public var paused = false {
        didSet {
            resetCurrentState()
        }
    }

    // MARK: Printing

    /// A human-readable, detailed description of all timing and frame count statistics.
    public var detailedDescription: String {
        let frameDurationAverage = frameDuration.average ?? 0
        let imageCopyDurationAverage = imageCopyDuration.average ?? 0
        let analysisDurationAverage = analysisDuration.average ?? 0
        let variance = (imageCopyDuration.variance ?? 0) + (analysisDuration.variance ?? 0) // Approximation

        let waiting = String(format: "%.1f%%", 100 * Double(waitingFrames) / Double(totalFrames))
        let dismissed = String(format: "%.1f%%", 100 * Double(dismissedFrames) / Double(totalFrames))

        let framerate = String(format: "%.1f Hz", 1 / frameDurationAverage)
        let timeslot = String(format: "%.1f ms", 1000 * frameDurationAverage)

        let processing = String(format: "%.1f ms", 1000 * (imageCopyDurationAverage + analysisDurationAverage))
        let deviation = String(format: "%.1f ms", 1000 * sqrt(variance))
        let imageCopying = String(format: "%.1f ms", 1000 * imageCopyDurationAverage)
        let analysis = String(format: "%.1f ms", 1000 * analysisDurationAverage)

        return """
        • Total frames: \(totalFrames)
            - not analyzed immediately: \(waiting)
            - totally dismissed: \(dismissed)
        • Avg. framerate: \(framerate)
            (which is a timeslot of \(timeslot))
        • Avg. image processing duration: \(processing); std-deviation: \(deviation)
            - image copying: \(imageCopying)
            - actual analysis: \(analysis)
        """
    }

    // MARK: Internal Methods

    private var lastFrameArrivalTime: Double?
    private var currentFrameAnalysisBeginTime: Double?

    /// Reset the state of last- and current-frame state variables.
    private func resetCurrentState() {
        lastFrameArrivalTime = nil
        currentFrameAnalysisBeginTime = nil
    }

    /// Call when a new frame arrives.
    internal func newFrame(frame: GameQueue.Frame) {
        guard !paused else { return }
        totalFrames += 1

        // Update average image copy duration
        let time = timeProvider.currentTime
        imageCopyDuration.add(value: time - frame.1)

        // Update average frame duration
        if let last = lastFrameArrivalTime {
            frameDuration.add(value: time - last)
        }
        lastFrameArrivalTime = time
    }

    /// Call when a frame was dropped.
    internal func frameDropped() {
        guard !paused else { return } // TODO: last frame -> other paused validation
        dismissedFrames += 1
    }

    /// Call when a frame has to wait for analysis.
    internal func frameCannotImmediatelyBeAnalyzed() {
        guard !paused else { return }
        waitingFrames += 1
    }

    /// Must be called in an alternating fashion with `currentFrameAnalysisEnded`, and always before `currentFrameAnalysisEnded`.
    internal func currentFrameAnalysisStarted() {
        guard !paused else { return }
        currentFrameAnalysisBeginTime = timeProvider.currentTime
    }

    /// Must be called in an alternating fashion with `currentFrameAnalysisStarted`, and always after `currentFrameAnalysisStarted`.
    internal func currentFrameAnalysisEnded() {
        guard !paused, let beginTime = currentFrameAnalysisBeginTime else { return }
        analysisDuration.add(value: timeProvider.currentTime - beginTime)
    }
}
