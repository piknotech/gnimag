//
//  Created by David Knothe on 25.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

/// A strategy which is used to keep the player jumping at a regular pace when there are currently no bars.
class IdleStrategy: InteractionSolutionStrategy {
    /// The percentage of the playfield height where the jump center should be.
    /// 0 means the jumps are as low as possible, and 1 means the jumps are as high as possible.
    let relativeIdleHeight: Double

    /// The minimal distance between two consecutive jumps.
    /// This is used to set an unlockTime (timeUntilEnd) which is respected by TapPredictor.
    let minimumJumpDistance: Double

    /// Default initializer.
    init(relativeIdleHeight: Double, minimumJumpDistance: Double) {
        self.relativeIdleHeight = relativeIdleHeight
        self.minimumJumpDistance = minimumJumpDistance
    }

    /// Calculate the solution for the given frame.
    /// Ignores the PlayerBarInteractions in the frame and just focuses on preventing the player from crashing the floor and jumping at a regular pace.
    func solution(for frame: PredictionFrame) -> Solution? {
        let startHeight = jumpStartHeight(for: frame), player = frame.player

        print(player.currentPosition.y, startHeight)

        // Jump immediately if player is too low
        if player.currentPosition.y < startHeight {
            return Solution(timeUntilStart: 0, jumpTimeDistances: [], timeUntilEnd: minimumJumpDistance)
        }

        // Else: Jump exactly when the player reaches the idle jump start height
        let yDistance = startHeight - player.currentJumpStart.y

        // Calculate time until reaching start height
        guard let solutions = QuadraticSolver.solve(frame.jumping.parabola, equals: yDistance) else {
            exit(withMessage: "IdleStrategy – This cannot happen!")
        }

        // Use larger of both solutions to jump as late as possible
        let timeFromJumpStart = max(solutions.0, solutions.1)
        let timeFromNow = timeFromJumpStart - player.timePassedSinceJumpStart
        return Solution(timeUntilStart: timeFromNow, jumpTimeDistances: [], timeUntilEnd: minimumJumpDistance)
    }

    /// The start height of an optimal idle jump (with respect to `relativeIdleHeight`).
    private func jumpStartHeight(for frame: PredictionFrame) -> Double {
        let range = frame.playfield.size - frame.jumping.jumpHeight
        return frame.playfield.lowerRadius + range * relativeIdleHeight
    }
}
