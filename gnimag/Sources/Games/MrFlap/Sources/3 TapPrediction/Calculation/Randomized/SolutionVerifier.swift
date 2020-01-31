//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

struct SolutionVerifier {
    typealias Solution = InteractionSolutionStrategy.Solution

    let playfield: PlayfieldProperties
    let player: PlayerProperties
    let jumping: JumpingProperties
    let interaction: PlayerBarInteraction

    /// Checks if the given solution fulfills a precondition. If not, the solution can immediately be discarded because it will not solve the interaction (and would receive a rating of 0).
    /// The precondition is a simple check whether the player passes through the left and right hole bounds.
    private static func precondition(forValidSolution solution: Solution, interaction: PlayerBarInteraction, player: PlayerProperties, jumping: JumpingProperties) -> Bool {
        // Left side. Attention: we assume the direction of the bounds curve (as it is always shaped like this)
        let leftSide = interaction.holeMovement.intersectionsWithBoundsCurves.left
        if solution.height(at: leftSide.xRange.lower, for: player, with: jumping) <= leftSide.yRange.lower { return false }
        if solution.height(at: leftSide.xRange.upper, for: player, with: jumping) >= leftSide.yRange.upper { return false }

        // Right side (same assumptions)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        if solution.height(at: rightSide.xRange.lower, for: player, with: jumping) >= rightSide.yRange.upper { return false }
        if solution.height(at: rightSide.xRange.upper, for: player, with: jumping) <= rightSide.yRange.lower { return false }

        return true
    }

    /// The rating of a given solution – higher is better.
    /// The rating depends on two factors: the tap time rating and the safety rating.
    /// The tap time rating is just the minimum distance between two consecutive jumps; the safety rating rates the player trajectory, i.e. the distance to playfield and bar hole bounds.
    /// These two factors are multiplied. The safety rating is in [0, 1], 0 meaning a definite crash or contact with the playfield bounds (which is bad for player jump tracking and is therefore avoided).
    private static func rating(of solution: Solution, interaction: PlayerBarInteraction, on playfield: Playfield, player: PlayerProperties, jumping: JumpingProperties) -> Double {
        // Determine time rating
        let timeDistanceForFirstJump = player.timePassedSinceJumpStart + solution.timeUntilStart
        let allTimeDistances = solution.jumpTimeDistances + [timeDistanceForFirstJump]
        let timeRating = allTimeDistances.min()!

        // Determine safety rating
        let safetyRating: Double = 1

        return timeRating * safetyRating
    }
}
