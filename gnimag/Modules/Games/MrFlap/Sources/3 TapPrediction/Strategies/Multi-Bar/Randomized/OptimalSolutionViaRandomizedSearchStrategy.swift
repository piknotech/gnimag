//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit
import Image

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
/// This class considers all bars in the frame.
class OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    /// The solution that was found during the previous call to `solution(for:on:)`.
    /// This is used as a starting point for the next calculation.
    private var lastSolution: Solution?

    /// The time of the previous frame.
    private var lastFrameTime: Double?

    /// The minimal distance between two consecutive jumps of generated solutions.
    /// If it is not possible to create solutions with this jump distance, it is ignored.
    private let minimumJumpDistance: Double

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.TapPrediction { debugLogger.currentFrame.tapPrediction }

    /// FramerateDetector limiting the total tap prediction duration.
    private var framerateDetector: FramerateDetector
    private var timeProvider: TimeProvider

    /// Default initializer.
    init(minimumJumpDistance: Double, logger: DebugLogger, framerate: FramerateDetector, timeProvider: TimeProvider) {
        self.minimumJumpDistance = minimumJumpDistance
        self.debugLogger = logger
        self.framerateDetector = framerate
        self.timeProvider = timeProvider
    }

    /// State whether produced solutions should be locked directly before executing a tap.
    var shouldLockSolution: Bool { true }

    /// When the number of required taps would be too high, the strategy decides that it would be insensible to try solving the full frame.
    func canSolve(frame: PredictionFrame) -> Bool {
        guard let taps = minimumNumberOfTaps(for: frame) else { return false }
        return taps <= 5
    }

    /// The minimum number of taps that are required to solve the frame.
    /// Returns nil when the frame cannot be solved because the vertical distance to the bar hole is too high.
    private func minimumNumberOfTaps(for frame: PredictionFrame) -> Int? {
        SolutionGenerator(frame: frame).minimumNumberOfTaps
    }

    /// Calculate the solution for the given frame.
    func solution(for frame: PredictionFrame) -> Solution? {
        let startTime = timeProvider.currentTime

        // Create generator and verifier
        let generator = SolutionGenerator(frame: frame)
        let verifier = SolutionVerifier(frame: frame)

        var bestSolution: Solution? = nil
        var bestRating: Double = 0
        let isSingleBar = frame.bars.count == 1

        // Function to evaluate a solution and update the best solution if required.
        func evaluate(_ solution: Solution) {
            // Performance-shortcut: avoid evaluating `rating` if possible
            if verifier.precondition(forValidSolution: solution) {
                let rating = verifier.rating(of: solution, requiredMinimum: 1.01 * bestRating, considerFinalJump: isSingleBar)
                if rating > bestRating {
                    bestSolution = solution
                    bestRating = rating
                }
            }
        }

        // Try reusing last solution
        let frameDiff = frame.currentTime - (lastFrameTime ?? frame.currentTime)
        lastFrameTime = frame.currentTime

        if var last = (lastSolution.flatMap { $0.shifted(by: frameDiff) }) {
            let duration = generator.zeroSolution.unlockDuration
            last = Solution(relativeTimes: last.relativeTapTimes, unlockDuration: duration)
            evaluate(last)
        }

        // Try 0-solution
        evaluate(generator.zeroSolution)

        // Generate random solutions
        // Consider: 1000 solutions don't seem much, but: once a (good enough) solution is available, all generated solutions will just get better and better (because they have to obey minimum requirements to be able to beat the current best solution, therefore SolutionGenerator will generate only sensible solutions, designed to beat the currently best solution).
        // Combined with the fact that the best solution from the last frame is used as a starting point, this leads to an immensely good final solution after (60fps * 1000solutions/frame) = 60,000 solutions generated in e.g. 1 second.
        let numTries = 1000

        let endTime = startTime + (framerateDetector.frameDistance ?? .greatestFiniteMagnitude) / 2

        var currentTry = 0
        var respectMinimumTapDistance = true
        var hasToggledMinimumTapDistance = false

        while true {
            if timeProvider.currentTime > endTime || (currentTry > numTries && hasToggledMinimumTapDistance) { break }

            // Generate and evaluate solution
            let minTapDistance = respectMinimumTapDistance ? max(minimumJumpDistance, bestRating) : bestRating
            if let solution = generator.randomSolution(minimumConsecutiveTapDistance: minTapDistance, increaseMinimumTapDistanceForLargeNumberOfTaps: false) {
                evaluate(solution)
            }

            // Increase currentTry
            currentTry += 1

            if currentTry > numTries && !hasToggledMinimumTapDistance {
                // Only ignore minimum jump distance if it didn't yield a valid solution
                if bestRating > 0 {
                    break
                } else {
                    currentTry = 0
                    respectMinimumTapDistance.toggle()
                    hasToggledMinimumTapDistance = true
                }
            }
        }

        // Log solution or, if idle strategy is chosen, zero solution
        let solution = bestSolution ?? generator.zeroSolution
        let fineGrainedRating = verifier.fineGrainedRating(for: solution, considerFinalJump: isSingleBar)
        debug.fineGrainedRating = fineGrainedRating

        lastSolution = bestSolution
        return (bestRating == 0) ? nil : bestSolution
    }
}
