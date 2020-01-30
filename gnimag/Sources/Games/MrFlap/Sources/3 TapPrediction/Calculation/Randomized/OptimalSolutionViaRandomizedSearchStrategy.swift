//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
struct OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    typealias Solution = JumpSequenceFromCurrentPosition

    /// The solution that was found during the previous call to `solution(for:on:)`.
    /// This is used as a starting point for the next calculation.
    private var lastSolution: Solution?

    /// Calculate the solution for the given interaction properties.
    func solution(for interaction: PlayerBarInteraction, on playfield: PlayfieldProperties, player: PlayerProperties, jumping: JumpingProperties) -> JumpSequenceFromCurrentPosition {
        print(Self.minimumNumberOfTaps(for: interaction, player: player, jump: jumping))
        return JumpSequenceFromCurrentPosition(timeUntilStart: 10, jumpTimeDistances: [], timeUntilEnd: 0)
    }

    /// A value where it is not possible to complete the interaction with less taps.
    /// This is a required value for the number of taps; not necessarily a sufficient one.
    static func minimumNumberOfTaps(for interaction: PlayerBarInteraction, player: PlayerProperties, jump: JumpingProperties) -> Int? {
        // Calculate distance for the lower right point of the hole (respective to the last jump start of the player)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        var heightDiff = rightSide.yRange.lower - player.lastJumpStart.y
        var T = rightSide.xRange.upper + player.timePassedSinceJumpStart // We consider the timespan since the last jump

        // First: Try performing N equistant jumps in [0,T] (this is the strategy achieving the highest end result after N jumps)
        // --> Find smallest N with hDiff <= N * f(T/N) (f being the jump parabola)
        if jump.jumpVelocity * T < heightDiff { return nil } // Target too high
        var N = Int(ceil(0.5 * jump.gravity * T * T / (jump.jumpVelocity * T - heightDiff)))

        // Check if solution is possible
        if T / Double(N) >= player.timePassedSinceJumpStart { return N - 1 } // Ignore current jump

        // Then: If the jump sequence is impossible (i.e. the first tap is in the past because we considered the larger time interval), adapt the strategy to start the jump now (i.e. reduce the interval).
        // This yields a worse result than the first approach, but is still the best result (as the first approach is impossible).
        heightDiff = rightSide.yRange.lower - player.currentPosition.y
        T = rightSide.xRange.upper

        if jump.jumpVelocity * T < heightDiff { return nil } // Target too high

        // Same as above; return N (instead of N-1) because the initial jump is not included anymore
        N = Int(ceil(0.5 * jump.gravity * T * T / (jump.jumpVelocity * T - heightDiff)))
        return N
    }
}
