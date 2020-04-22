//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
/// Currently, this class only considers the first bar in the frame.
class OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    /// The solution that was found during the previous call to `solution(for:on:)`.
    /// This is used as a starting point for the next calculation.
    private var lastSolution: Solution?

    /// The time of the previous frame.
    private var lastFrameTime: Double?

    /// The minimal distance between two consecutive jumps of generated solutions.
    /// If it is not possible to create solutions with this jump distance, it is ignored.
    private let minimumJumpDistance: Double

    /// Default initializer.
    init(minimumJumpDistance: Double) {
        self.minimumJumpDistance = minimumJumpDistance
    }

    /// The minimum number of taps that are required to solve the frame.
    /// Returns nil when the frame cannot be solved because the vertical distance to the bar hole is too high.
    func minimumNumberOfTaps(for frame: PredictionFrame) -> Int? {
        SolutionGenerator(frame: frame).minimumNumberOfTaps
    }
    
    /// Calculate the solution for the given frame.
    func solution(for frame: PredictionFrame) -> Solution? {
        // Create generator and verifier
        let generator = SolutionGenerator(frame: frame)
        let verifier = SolutionVerifier(frame: frame)

        // Shift last solution and use it as starting point
        let frameDiff = frame.currentTime - (lastFrameTime ?? frame.currentTime)
        lastFrameTime = frame.currentTime

        var bestSolution = lastSolution.flatMap { $0.shifted(by: frameDiff) }
        var bestRating = bestSolution.map { verifier.rating(of: $0, requiredMinimum: 0) } ?? 0

        // Generate random solutions
        // Consider: 500 solutions doesn't seem much, but: once a (good enough) solution is available, all generated solutions will just get better and better (because they have to obey minimum requirements to be able to beat the current best solution, therefore SolutionGenerator will generate only sensible solutions, designed to beat the currently best solution).
        // Combined with the fact that the best solution from the last frame is used as a starting point, this leads to an immensely good final solution after (60fps * 1000solutions/frame) = 60,000 solutions generated in e.g. 1 second.
        let numTries = 1000

        for respectMinimumTapDistance in [true, false] {
            numTries.repeat {
                let minTapDistance = respectMinimumTapDistance ? max(minimumJumpDistance, bestRating) : bestRating

                guard let solution = generator.randomSolution(minimumConsecutiveTapDistance: minTapDistance, increaseMinimumTapDistanceForLargeNumberOfTaps: false) else { return }

                // Performance-shortcut: avoid evaluating `rating` if possible
                guard verifier.precondition(forValidSolution: solution) else { return }

                // Calculate rating and update best solution
                let rating = verifier.rating(of: solution, requiredMinimum: bestRating)
                if rating > bestRating {
                    bestSolution = solution
                    bestRating = rating
                }
            }

            // Only ignore minimum jump distance if it didn't yield a valid solution
            if bestRating > 0 { break }
        }

        lastSolution = bestSolution
        return (bestRating == 0) ? nil : bestSolution
    }
}
