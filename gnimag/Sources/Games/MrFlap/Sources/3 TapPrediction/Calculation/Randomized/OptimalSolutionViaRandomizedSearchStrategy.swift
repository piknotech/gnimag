//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
struct OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    /// The solution that was found during the previous call to `solution(for:on:)`.
    /// This is used as a starting point for the next calculation.
    private var lastSolution: Solution?

    /// Calculate the solution for the given interaction properties.
    func solution(for interaction: PlayerBarInteraction, on playfield: PlayfieldProperties, player: PlayerProperties, jumping: JumpingProperties) -> Solution? {
        // Create generator and verifier
        let verifier = SolutionVerifier(playfield: playfield, player: player, jumping: jumping, interaction: interaction)
        let generator = SolutionGenerator(playfield: playfield, player: player, jumping: jumping, interaction: interaction, bestSolution: lastSolution)

        return Solution(timeUntilStart: 10, jumpTimeDistances: [], timeUntilEnd: 0)
    }
}
