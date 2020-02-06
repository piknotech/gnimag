//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
class OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    /// The solution that was found during the previous call to `solution(for:on:)`.
    /// This is used as a starting point for the next calculation.
    private var lastSolution: Solution?

    /// The time of the previous frame.
    private var lastFrameTime: Double?

    /// Calculate the solution for the given frame.
    func solution(for frame: PredictionFrame) -> Solution? {
        // Create generator and verifier
        let generator = SolutionGenerator(frame: frame)
        let verifier = SolutionVerifier(frame: frame)

        // Shift last solution and use it as starting point
        let frameDiff = frame.currentTime - (lastFrameTime ?? frame.currentTime)
        lastFrameTime = frame.currentTime

        var bestSolution = lastSolution.flatMap { shift(solution: $0, by: frameDiff) }
        var bestRating = bestSolution.map { verifier.rating(of: $0, requiredMinimum: 0) } ?? 0

        // Generate random solutions
        // Consider: 250 solutions doesn't seem much, but: once a (good enough) solution is available, all generated solutions will just get better and better (because they have to obey minimum requirements to be able to beat the current best solution, therefore SolutionGenerator will generate only sensible solutions, designed to beat the currently best solution).
        // Combined with the fact that the best solution from the last frame is used as a starting point, this leads to an immensely good final solution after (60fps * 250solutions/frame) = 15,000 solutions generated in e.g. 1 second.
        let numTries = 250

        numTries.repeat {
            guard let solution = generator.randomSolution(minimumConsecutiveTapDistance: bestRating) else { return }

            // Performance-shortcut: avoid evaluating `rating` if possible
            guard verifier.precondition(forValidSolution: solution) else { return }

            // Calculate rating and update best solution
            let rating = verifier.rating(of: solution, requiredMinimum: bestRating)
            if rating > bestRating {
                bestSolution = solution
                bestRating = rating
            }
        }

        lastSolution = bestSolution
        return bestSolution
    }

    /// Shift a solution by a given time. This is used to transform a solution from a different frame to the current frame by changing the `timeUntilStart` value.
    /// Use positive `shift` values to transform a solution from a previous frame into the current frame.
    /// If the solution would be invalid after shifting (i.e. begin in the past), return nil.
    private func shift(solution: Solution, by shift: Double) -> Solution? {
        let timeUntilStart = solution.timeUntilStart - shift
        if timeUntilStart < 0 { return nil }
        return Solution(timeUntilStart: timeUntilStart, jumpTimeDistances: solution.jumpTimeDistances, timeUntilEnd: solution.timeUntilEnd)
    }
}
