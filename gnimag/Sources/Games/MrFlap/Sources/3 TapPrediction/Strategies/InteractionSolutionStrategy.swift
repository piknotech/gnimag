//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// InteractionSolutionStrategy "solves" a PredictionFrame in such a way that it provides a tap sequence that allows the player from its current time and position to pass the relevant bar(s) without colliding.
protocol InteractionSolutionStrategy {
    /// Determine whether or not the strategy can or wants to find a solution for a given frame.
    /// This does not mean that `solution(for:)` will return a non-nil result.
    /// Do not call `solution(for:)` when this returns false.
    func canSolve(frame: PredictionFrame) -> Bool

    /// Provide a solution for the frame if possible.
    func solution(for frame: PredictionFrame) -> Solution?

    /// State whether produced solutions should be locked directly before executing a tap.
    var shouldLockSolution: Bool { get }
}
