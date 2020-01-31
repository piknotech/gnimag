//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

/// SolutionGenerator generates a set of possible solutions to a given interaction.
/// These solutions can be required to meet certain requirements, e.g. a minimum distance between consecutive taps etc.
struct SolutionGenerator {
    typealias Solution = InteractionSolutionStrategy.Solution

    let playfield: PlayfieldProperties
    let player: PlayerProperties
    let jumping: JumpingProperties
    let interaction: PlayerBarInteraction

    /// The current best solution, as rated by SolutionVerifier.
    /// Update from outside after improving the best solution.
    var bestSolution: Solution?

    /// Generate a random solution meeting the requirements.
    /// Returns nil if it is not possible to solve the interaction or to meet the requirements.
    func randomSolution(minimumConsecutiveTapDistance: Double) -> Solution? {
        guard let minTaps = minimumNumberOfTaps else { return nil } // Else, impossible
        // ...
        return nil
    }

    /// Pick a random number of taps between the given interval.
    /// Thereby, the minimum is the minimum required number of taps to solve the interaction.
    private func randomNumberOfTaps(
        minimum: Int,
        maximum: Int?,
        currentBest: Int?
    ) -> Int {
        0
    }

    /// A value where it is not possible to complete the interaction (i.e. pass the bar) with less taps.
    /// This is a required value for the number of taps; not necessarily a sufficient one.
    private var minimumNumberOfTaps: Int? {
        // Calculate distance for the lower right point of the hole (respective to the last jump start of the player)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        var heightDiff = rightSide.yRange.lower - player.lastJumpStart.y
        var T = rightSide.xRange.upper + player.timePassedSinceJumpStart // We consider the timespan since the last jump

        // First: Try performing N equistant jumps in [0,T] (this is the strategy achieving the highest end result after N jumps)
        // --> Find smallest N with hDiff <= N * f(T/N) (f being the jump parabola)
        if jumping.jumpVelocity * T < heightDiff { return nil } // Target too high
        var N = Int(ceil(0.5 * jumping.gravity * T * T / (jumping.jumpVelocity * T - heightDiff)))

        // Check if solution is possible
        if T / Double(N) >= player.timePassedSinceJumpStart { return N - 1 } // Ignore current jump as it is already executed

        // Then: If the jump sequence is impossible (i.e. the first tap is in the past because we considered the larger time interval), adapt the strategy to start the jump now (i.e. reduce the interval).
        // This yields a worse result than the first approach, but is still the best result (as the first approach is impossible).
        heightDiff = rightSide.yRange.lower - player.currentPosition.y
        T = rightSide.xRange.upper

        if jumping.jumpVelocity * T < heightDiff { return nil } // Target too high

        // Same as above, but return N (instead of N-1) because the initial jump is not included anymore
        N = Int(ceil(0.5 * jumping.gravity * T * T / (jumping.jumpVelocity * T - heightDiff)))
        return N
    }
}

// MARK: - Poisson

private enum Poisson {
    /// Generate a random variable distributed by the possion(lambda) distribution.
    /// lambda (> 0) is the expected value of the random variable.
    /// Requires O(lambda) time (on average).
    private static func poissonSample(lambda: Double) -> Int {
        let L = exp(-lambda)
        var k = 0, p = Double(1)

        while p > L {
            k += 1
            p *= .random(in: 0 ... 1)
        }

        return k - 1
    }
}

// MARK: - RandomPoints

private enum RandomPoints {
    /// Returns an array of size `numPoints` containing evenly distributed points in the given range. The range must be regular.
    /// Additionally, the distance between each pair of points is at least `minimumDistance`.
    /// Returns nil if it is not possible to satisfy this condition.
    static func on(_ range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int) -> [Double]? {
        let reducedLength = range.upper - range.lower - Double(numPoints - 1) * minimumDistance
        let reducedRange = SimpleRange(from: range.lower, to: range.lower + reducedLength)

        // If the required minimum distance is too large (respective to N), the reduced range is empty
        if reducedRange.isEmpty { return nil }

        // Calculate N points on the reduced interval
        var points = (0 ..< numPoints).map { _ in random(in: reducedRange) }
        points.sort()

        // Shift points upwards to satisfy minimum distance
        points = points.enumerated().map { i, point in
            point + Double(i) * minimumDistance
        }

        return points
    }

    /// Return a random point in the given range. The range must be regular.
    private static func random(in range: SimpleRange<Double>) -> Double {
        .random(in: range.lower ... range.upper)
    }
}
