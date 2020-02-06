//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit

/// SolutionGenerator generates a set of possible solutions to a given interaction.
/// These solutions can be required to meet certain requirements, e.g. a minimum distance between consecutive taps etc.
struct SolutionGenerator {
    typealias Solution = InteractionSolutionStrategy.Solution

    let playfield: PlayfieldProperties
    let player: PlayerProperties
    let jumping: JumpingProperties
    let interaction: PlayerBarInteraction

    /// The minimum number of taps that is required to complete the interaction.
    /// As this does not change, it is calculated once.
    let minimumNumberOfTaps: Int?

    /// Default initializer.
    init(playfield: PlayfieldProperties, player: PlayerProperties, jumping: JumpingProperties, interaction: PlayerBarInteraction) {
        self.playfield = playfield
        self.player = player
        self.jumping = jumping
        self.interaction = interaction

        minimumNumberOfTaps = Self.calculateMinimumNumberOfTaps(playfield: playfield, player: player, jumping: jumping, interaction: interaction)
    }

    /// Generate a random solution meeting the requirements.
    /// Returns nil if it is not possible to solve the interaction or to meet the requirements.
    func randomSolution(minimumConsecutiveTapDistance: Double) -> Solution? {
        let T = interaction.holeMovement.intersectionsWithBoundsCurves.right.xRange.upper
        guard var taps = randomNumberOfTaps else { return nil }

        // Calculate tap range
        let minimumFirstTap = max(0, minimumConsecutiveTapDistance - player.timePassedSinceJumpStart)
        let tapRange = SimpleRange(from: minimumFirstTap, to: T)

        // Decrease number of taps if it would be impossible to satisfy `minimumConsecutiveTapDistance`
        if minimumConsecutiveTapDistance > 0 {
            taps = min(Int(ceil(tapRange.size / minimumConsecutiveTapDistance)), taps)
        }
        
        guard let points = RandomPoints.on(tapRange, minimumDistance: minimumConsecutiveTapDistance, numPoints: taps, maximumValueForFirstPoint: maxTimeForFirstTap) else { return nil }

        return solutionFromRandomPointsSequence(points, T: T)
    }

    /// Convert a random points sequence (as obtained from `RandomPoints.on(_:)`) into a Solution.
    private func solutionFromRandomPointsSequence(_ points: [Double], T: Double) -> Solution {
        // Find time differences between subsequent elements
        let points = [0] + points + [T]
        var differences = (1 ..< points.count).map { i -> Double in
            points[i] - points[i-1]
        }

        // Extract start and end time and create solution
        let timeUntilStart = differences.removeFirst()
        let timeUntilEnd = differences.removeLast()

        return Solution(timeUntilStart: timeUntilStart, jumpTimeDistances: differences, timeUntilEnd: timeUntilEnd)
    }

    /// Pick a positive random number of taps.
    /// It is always in the interval `[minTaps, minTaps + 1]` as these are the two values where the optimal solution (normally) comes from.
    private var randomNumberOfTaps: Int? {
        guard var minTaps = minimumNumberOfTaps else { return nil }
        minTaps = max(1, minTaps)
        let maxTaps = minTaps + 1 // In MrFlap, solution is always in [minTaps, minTaps + 1]

        return Distributions.binomialSample(in: minTaps ... maxTaps, average: 0.5 * Double(minTaps + maxTaps))
    }

    /// A value where it is not possible to complete the interaction (i.e. pass the bar) with less taps.
    /// This is a required value for the number of taps; not necessarily a sufficient one.
    private static func calculateMinimumNumberOfTaps(playfield: PlayfieldProperties, player: PlayerProperties, jumping: JumpingProperties, interaction: PlayerBarInteraction) -> Int? {
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
        let values = n.timesMake { Double.random(in: 0 ..< 1) }
        return values.count { $0 < p }
    }

    /// Generate a random variable distributed by the binomial distribution inside the given range with the given average value.
    /// Requires O(n) time, where n is the size of the range.
    static func binomialSample(in range: ClosedRange<Int>, average: Double) -> Int {
        let offset = range.lowerBound, size = range.upperBound - range.lowerBound
        let p = (average - Double(offset)) / Double(size)
        return offset + binomialSample(n: size, p: p)
    }
}
