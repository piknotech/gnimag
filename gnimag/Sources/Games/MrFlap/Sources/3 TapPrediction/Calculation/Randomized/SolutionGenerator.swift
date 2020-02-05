//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import HandySwift

/// SolutionGenerator generates a set of possible solutions to a given interaction.
/// These solutions can be required to meet certain requirements, e.g. a minimum distance between consecutive taps etc.
struct SolutionGenerator {
    typealias Solution = InteractionSolutionStrategy.Solution

    let playfield: PlayfieldProperties
    let player: PlayerProperties
    let jumping: JumpingProperties
    let interaction: PlayerBarInteraction

    /// Generate a random solution meeting the requirements.
    /// Returns nil if it is not possible to solve the interaction or to meet the requirements.
    func randomSolution(minimumConsecutiveTapDistance: Double?, currentBestNumberOfTaps: Int?) -> Solution? {
        let T = interaction.holeMovement.intersectionsWithBoundsCurves.right.xRange.upper

        // Find min and max tap distances
        guard let minTaps = minimumNumberOfTaps else { return nil } // Else, impossible // TODO: Only calculate once!
        let maxTaps = minimumConsecutiveTapDistance.map { Int(ceil(T / $0)) }

        // Generate random solution
        // TODO: allow empty solution? i.e. zero taps
        let taps = pickRandomNumberOfTaps(minimum: max(1, minTaps), maximum: maxTaps, currentBest: currentBestNumberOfTaps)
        let tapRange = SimpleRange(from: 0, to: T)
        guard let points = RandomPoints.on(tapRange, minimumDistance: minimumConsecutiveTapDistance ?? 0, numPoints: taps, maximumValueForFirstPoint: maxTimeForFirstTap) else { return nil }

        return solutionFromRandomPointsSequence(points, T: T)

        // todo: after verification: remove last tap, if possible?
    }

    /// Convert a random points sequence (as obtained from `RandomPoints.on(_:)`) into a Solution.
    private func solutionFromRandomPointsSequence(_ points: [Double], T: Double) -> Solution {
        // "Anti-scan" the array to find the element differences
        var lastValue: Double = 0
        var differences = points.map { element -> Double in
            let diff = element - lastValue
            lastValue = element
            return diff
        }

        // Find start and end time and create solution
        let timeUntilStart = differences.removeFirst()
        let timeUntilEnd = T - points.last!

        return Solution(timeUntilStart: timeUntilStart, jumpTimeDistances: differences, timeUntilEnd: timeUntilEnd)
    }

    /// Pick a (positive) random number of taps between the given interval.
    /// Thereby, the minimum is the minimum required number of taps to solve the interaction.
    /// All parameters must be positive.
    private func pickRandomNumberOfTaps(minimum: Int, maximum: Int?, currentBest: Int?) -> Int {
        switch (maximum, currentBest) {
        case let (.some(maximum), .some(currentBest)):
            // Use a mix of `minimum` and `currentBest` as average (to hinder bad solutions from affecting the choice in a bad way, as the best solutions are often very near the `minimum` value)
            var average = Double(minimum + currentBest) / 2
            average.clamp(to: Double(minimum + 1) ... Double(maximum - 1)) // Allow a bit of leeway
            return Distributions.binomialSample(in: minimum ... maximum, average: average)

        case let (.none, .some(currentBest)):
            var average = Double(minimum + currentBest) / 2
            average.clamp(to: Double(minimum + 1)...)
            return Distributions.poissonSample(in: minimum..., average: average)

        case let (.some(maximum), .none):
            // `minimum + 1` is often a good approximation for real solutions
            return Distributions.binomialSample(in: minimum ... maximum, average: Double(minimum + 1))

        case (.none, .none):
            return Distributions.poissonSample(in: minimum..., average: Double(minimum + 1))
        }
    }

    /// A value where it is not possible to complete the interaction (i.e. pass the bar) with less taps.
    /// This is a required value for the number of taps; not necessarily a sufficient one.
    private var minimumNumberOfTaps: Int? {
        // Calculate distance for the lower right point of the hole (respective to the current jump start of the player)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        var heightDiff = rightSide.yRange.lower - player.currentJumpStart.y
        var T = rightSide.xRange.upper + player.timePassedSinceJumpStart // Consider the full timespan starting at the jump start

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

    /// The time (from now) in which the first tap must be executed to not hit the playfield floor.
    private var maxTimeForFirstTap: Double {
        let heightDiff = playfield.lowerRadius - player.currentJumpStart.y
        guard let solutions = QuadraticSolver.solve(jumping.parabola, equals: heightDiff) else { return .infinity }

        // Return larger (future) solution; subtract frame shift
        return max(solutions.0, solutions.1) - player.timePassedSinceJumpStart
    }
}

// MARK: - Distributions

private enum Distributions {
    /// Generate a random variable distributed by the possion(lambda) distribution.
    /// lambda (nonnegative) is the expected value of the random variable.
    /// Requires O(lambda) time (on average).
    static func poissonSample(lambda: Double) -> Int {
        if lambda <= 0 { return 0 }

        let L = exp(-lambda)
        var k = 0, p = Double(1)

        while p > L {
            k += 1
            p *= .random(in: 0 ... 1)
        }

        return k - 1
    }

    /// Generate a random variable distributed by the possion distribution inside the given half-open range.
    /// Requires O(lambda) time (on average), where `lambda = average - range.lowerBound`.
    static func poissonSample(in range: PartialRangeFrom<Int>, average: Double) -> Int {
        let lambda = average - Double(range.lowerBound)
        return range.lowerBound + poissonSample(lambda: lambda)
    }

    /// Generate a random variable distributed by the binomial(n, p) distribution.
    /// n must be nonnegative.
    /// Requires O(n) time.
    static func binomialSample(n: Int, p: Double) -> Int {
        let values = n.timesMake { Double.random(in: 0 ..< 1) }
        return values.count { $0 < p }
    }

    /// Generate a random variable distributed by the binomial distribution inside the given range with the given average value.
    /// Requires O(n) time, where n is the size of the range.
    static func binomialSample(in range: ClosedRange<Int>, average: Double) -> Int {
        let offset = range.lowerBound, size = range.upperBound - range.lowerBound
        let p = average / Double(size)
        return offset + binomialSample(n: size, p: p)
    }
}
