//
//  Created by David Knothe on 12.02.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Surge

extension Double: HasDistance {
    public func distance(to other: Double) -> Double {
        abs(self - other)
    }
}

/// Beneath detecting the framerate, FramerateDetector also determines the offset, which allows predicting the exact timepoints of future frames.
public class FramerateDetector {
    public var frameDistance: Double? {
        tracker.slope ?? distanceGuess
    }

    private var state: State = .detectingApproximateFramerate
    enum State {
        /// Before starting to create a linear regression, it is important to calculate the approximate frame distance.
        /// This allows to determine whether a distance of 0.33s is 1 or 2 frames without having a regression function.
        case detectingApproximateFramerate

        /// After having determined the single smallest frame distance, FramerateDetector uses a linear regression to determine the exact frame duration and offset.
        case hasDetectedApproximateFramerate
    }

    // Only used in stage 1:
    private var distances = [Double]()
    private var lastFrameTime: Double?
    private var distanceGuess: Double?

    // Only used in stage 2:
    public let tracker = LinearTracker(maxDataPoints: 50, tolerance: .absolute(0), maxDataPointsForLogging: 1000)
    private var nextIndex = 0.0


    /// Default initializer.
    public init() {
    }

    /// Call each time a new frame arrives.
    public func newFrame(time: Double) {
        defer { lastFrameTime = time }

        switch state {
        case .detectingApproximateFramerate:
            // Store distance, update last time
            if let lastFrameTime = lastFrameTime { distances.append(time - lastFrameTime) }

            // Perform clustering after having collected 100 distances
            if distances.count >= 100 {
                let clusters = SimpleClustering.from(distances, maxDistance: distances.min()! / 3)
                let averages = clusters.clusters.map { mean($0.objects) }.sorted()
                let distance = averages.first!
                Terminal.log(.info, String(format: "Approximated frame duration: %.1f ms", 1000 * distance))

                // Move to stage 2
                state = .hasDetectedApproximateFramerate
                tracker.tolerance = .absolute(distance / 3)
                distanceGuess = distance
                distances.scan(initial: 0, +).forEach(addToTracker(time:))
            }

        case .hasDetectedApproximateFramerate:
            addToTracker(time: time)
        }
    }

    /// Add a frame time to the tracker. Thereby, calculate how many frames were skipped to maintain the linear regression whose slope determines the average frame distance.
    private func addToTracker(time: Double) {
        if tracker.hasRegression && tracker.isDataPointValid(value: time, time: nextIndex) {
            tracker.add(value: time, at: nextIndex)
            nextIndex += 1
        }
        else {
            // Calculate how many frames were skipped
            var skipped: Double = 0
            if let last = tracker.values.last {
                skipped = (time - last) / frameDistance! - 1
            }
            if abs(skipped - round(skipped)) < 0.25 {
                // Add value, considering the number of skipped frames
                nextIndex += round(skipped)
                tracker.add(value: time, at: nextIndex)
                nextIndex += 1
            }
            else {
                Terminal.log(.warning, "Frame time didn't match any frame slot! (skipped: \(skipped))")
            }
        }
    }

    /// Predict all frame timepoints inside the interval.
    public func frameMoments(in interval: SimpleRange<Double>) -> [Double]? {
        guard let regression = tracker.regression else { return nil }
        let from = LinearSolver.solve(regression, equals: interval.lower)!
        let to = LinearSolver.solve(regression, equals: interval.upper)!

        return (Int(ceil(from)) ... Int(floor(to))).map(Double.init).map(regression.at)
    }

    /// Round the value to the nearest frame time around it. If there is no regression yet, return the input value.
    @inline(__always)
    public func tryRoundingToNearestFrame(time: Double) -> Double {
        guard let regression = tracker.regression else { return time }
        let frame = LinearSolver.solve(regression, equals: time)!
        return regression.at(round(frame))
    }
}
