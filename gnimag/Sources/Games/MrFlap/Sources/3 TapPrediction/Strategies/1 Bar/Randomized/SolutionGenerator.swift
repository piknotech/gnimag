//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit

/// SolutionGenerator generates a set of possible solutions to a given interaction.
/// These solutions can be required to meet certain requirements, e.g. a minimum distance between consecutive taps etc.
/// Currently, this class only considers the first bar in the frame.
struct SolutionGenerator {
    let frame: PredictionFrame
    var interaction: PlayerBarInteraction { frame.bars.first! }

    /// The minimum number of taps that is required to complete the interaction.
    /// As this does not change, it is calculated once.
    let minimumNumberOfTaps: Int?

    /// The time (from now) in which the first tap must be executed to not hit the playfield floor.
    /// As this does not change, it is calculated once.
    let maxTimeForFirstTap: Double

    /// Default initializer.
    init(frame: PredictionFrame) {
        self.frame = frame

        minimumNumberOfTaps = Self.calculateMinimumNumberOfTaps(for: frame)
        maxTimeForFirstTap = Self.calculateMaxTimeForFirstTap(for: frame)
    }

    /// Generate a random solution meeting the requirements.
    /// Returns nil if it is not possible to solve the interaction or to meet the requirements.
    func randomSolution(minimumConsecutiveTapDistance: Double, increaseMinimumTapDistanceForLargeNumberOfTaps: Bool) -> Solution? {
        let T = interaction.fullInteractionRange.upper
        guard var taps = randomNumberOfTaps else { return nil }

        // Calculate tap range
        let minimumFirstTap = max(0, minimumConsecutiveTapDistance - frame.player.timePassedSinceJumpStart)
        let tapRange = SimpleRange(from: minimumFirstTap, to: T)

        // Decrease number of taps if it would be impossible to satisfy `minimumConsecutiveTapDistance`
        if minimumConsecutiveTapDistance > 0 {
            taps = max(1, min(Int(ceil(tapRange.size / minimumConsecutiveTapDistance)), taps))
        }
        
        guard let points = RandomPoints.on(tapRange, minimumDistance: minimumConsecutiveTapDistance, numPoints: taps, maximumValueForFirstPoint: maxTimeForFirstTap) else { return nil }

        // Convert into Solution
        return Solution(relativeTimes: points, unlockDuration: T)
    }

    /// Pick a positive random number of taps.
    /// It is always in the interval `[minTaps, minTaps + 1]` as these are the two values where the optimal solution always comes from.
    private var randomNumberOfTaps: Int? {
        guard var minTaps = minimumNumberOfTaps else { return nil }
        minTaps = max(1, minTaps)

        // We choose a number of taps in the range [minTaps, minTaps + 1].
        // In MrFlap, the optimal solution is always in this range – there are no cases where more taps are required to produce a better solution.
        if RandomPoints.fiftyFifty() {
            return minTaps
        } else {
            return minTaps + 1
        }
    }

    /// A value where it is not possible to complete the interaction (i.e. pass the bar) with less taps.
    /// This is a required value for the number of taps; not necessarily a sufficient one.
    private static func calculateMinimumNumberOfTaps(for frame: PredictionFrame) -> Int? {
        let player = frame.player, jumping = frame.jumping, interaction = frame.bars.first!

        // Calculate distance for the lower right point of the hole (respective to the current jump start of the player)
        let width = interaction.fullInteractionRange.upper
        let height = interaction.holeMovement.intersectionsWithBoundsCurves.right.yRange.lower
        var heightDiff = height - player.currentJumpStart.y
        var T = width + player.timePassedSinceJumpStart // Consider the full timespan starting at the jump start

        // First: Try performing N equistant jumps in [0,T] (this is the strategy achieving the highest end result after N jumps)
        // --> Find smallest N with hDiff <= N * f(T/N) (f being the jump parabola)
        if jumping.jumpVelocity * T < heightDiff { return nil } // Target too high
        var N = Int(ceil(0.5 * jumping.gravity * T * T / (jumping.jumpVelocity * T - heightDiff)))

        // Check if solution is possible
        if T / Double(N) >= player.timePassedSinceJumpStart { return N - 1 } // Ignore current jump as it is already executed

        // Then: If the jump sequence is impossible (i.e. the first tap is in the past because we considered the larger time interval), adapt the strategy to start the jump now (i.e. reduce the interval).
        // This yields a worse result than the first approach, but is still the best result (as the first approach is impossible).
        heightDiff = height - player.currentPosition.y
        T = width

        if jumping.jumpVelocity * T < heightDiff { return nil } // Target too high

        // Same as above, but return N (instead of N-1) because the initial jump is not included anymore
        N = Int(ceil(0.5 * jumping.gravity * T * T / (jumping.jumpVelocity * T - heightDiff)))
        return N
    }

    /// The time (from now) in which the first tap must be executed to not hit the playfield floor.
    private static func calculateMaxTimeForFirstTap(for frame: PredictionFrame) -> Double {
        let player = frame.player, jumping = frame.jumping, playfield = frame.playfield

        let heightDiff = playfield.lowerRadius - player.currentJumpStart.y
        guard let solutions = QuadraticSolver.solve(jumping.parabola, equals: heightDiff) else { return .infinity }

        // Return larger (future) solution; subtract frame shift
        return max(solutions.0, solutions.1) - player.timePassedSinceJumpStart
    }
}
