//
//  Created by David Knothe on 01.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// This WayToSpecificPointStrategy performs a minimal required amount of jumps to ascend or descend to the required end height level.
/// The distance between all consecutive jumps is the same. This means, each jump contributes the same regarding height ascension or descension.
/// This is an optimal strategy in the following sense: it achieves the maximal possible minimum distance between two consecutive jumps by spacing out all jumps equally.
struct LinearWayToSpecificPointStrategy: WayToSpecificPointStrategy {
    func jumpSequence(to endPoint: Point, in playfield: PlayfieldProperties, with player: PlayerProperties, jumping: JumpingProperties, currentTime: Double) -> JumpSequenceFromCurrentPosition {
        // Determine parameters
        let T = endPoint.time + player.timePassedSinceJumpStart
        let currentJumpTime = player.timePassedSinceJumpStart
        let height = endPoint.height - player.lastJumpStart.y // Height difference

        print(T, currentJumpTime, height)

        // Check if it is possible to reach the height
        let fullRange = SimpleRange(from: jumping.parabola.at(T), to: jumping.jumpVelocity * T, enforceRegularity: true)
        if !fullRange.contains(height) {
            fatalError("TODO: No jump sequence can reach \(height) because it is not inside the possible range \(fullRange).")
        }

        // Find solutions for different values of n and keep track of the best one (regarding its rating)
        var n = 1
        var bestSolution: Solution?

        // Increase n until it is impossible to generate better solutions
        while true {
            // Exit condition
            if (bestSolution?.rating ?? 0) > Solution.maximumPossibleRating(forN: n, T: T) { break }

            // Improve current solution if possible
            for solution in solutions(forReachingHeight: height, n: n, T: T, jumping: jumping, currentJumpTime: currentJumpTime) {

                print(solution.asSequence)
                let plot = JumpSequencePlot(sequence: solution.asSequence, player: player, playfield: playfield, jumping: jumping)
                plot.writeToDesktop(name: "plot_\(n)_\(solution.t).png")

                if !solution.isApplicable(in: playfield, jumping: jumping) { continue }
                if solution.rating > (bestSolution?.rating ?? 0) { bestSolution = solution }
            }

            n += 1
        }

        exit(0)

        // Convert solution into jump sequence
        return bestSolution!.asSequence
    }

    /// Returns all (0 or 2) solutions to endHeight(t) = height.
    /// The solutions are not necessarily valid.
    private func solutions(forReachingHeight height: Double, n N: Int, T: Double, jumping: JumpingProperties, currentJumpTime: Double) -> [Solution] {
        // Compute endHeight(t) = f(t) + n * f((T-t)/n), where f is the jump parabola
        let v = jumping.jumpVelocity, g = jumping.gravity, n = Double(N)
        let const = v*T - 1/2 * g*T*T/n
        let linear = g*T/n
        let quad = -1/2 * g*(n+1)/n
        let endHeight = Polynomial([const, linear, quad])

        // Solve endHeight(t) = height
        guard let (t1, t2) = QuadraticSolver.solve(a: endHeight.a, b: endHeight.b, c: endHeight.c - height) else { return [] }

        return [t1, t2].compactMap { t in
            Solution(T: T, currentJumpTime: currentJumpTime, t: t, n: N)
        }
    }
}

// MARK: Solution

/// A solution for reaching a given height.
/// The solution is parametrized by n (the number of jumps) and t (the time distance from the current jump start until the jump sequence starts).
private struct Solution {
    /// The total time from the beginning of the current jump until the required end time.
    let T: Double

    /// The time that has been elapsed in the current jump; i.e. the current position of the player.
    let currentJumpTime: Double

    /// The from the start of the current jump at which the jump series is begun and the first jump is made.
    let t: Double

    /// The number of jumps that will be performed.
    let n: Int

    /// States if the solution is valid/applicable, i.e. `t` is in a valid time range and the solution does not leave the playfield.
    func isApplicable(in playfield: PlayfieldProperties, jumping: JumpingProperties) -> Bool {
        if !SimpleRange(from: currentJumpTime, to: T).contains(t) { return false }

        let jumpLength = (T-t) / Double(n)
        jumping.jumpHeight

        // TODO: playfield
        return true
    }

    /// The rating of the solution, which is defined as the smallest distance between two consecutive jumps.
    /// A larger rating is better.
    var rating: Double {
        min(t, (T-t) / Double(n))
    }

    /// The largest rating that can be achieved by a solution with a given n.
    /// This is monotonically decreasing with larger n.
    static func maximumPossibleRating(forN n: Int, T: Double) -> Double {
        T / Double(n+1)
    }

    /// Convert the solution into a JumpSequence.
    var asSequence: JumpSequenceFromCurrentPosition {
        JumpSequenceFromCurrentPosition(
            timeUntilStart: t - currentJumpTime,
            jumpTimeDistances: [Double](repeating: (T-t) / Double(n), count: n - 1),
            timeUntilEnd: (T-t) / Double(n)
        )
    }
}

