//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit

struct SolutionVerifier {
    typealias Solution = InteractionSolutionStrategy.Solution

    let playfield: PlayfieldProperties
    let player: PlayerProperties
    let jumping: JumpingProperties
    let interaction: PlayerBarInteraction

    /// Checks if the given solution fulfills a precondition. If not, the solution can immediately be discarded because it will probably not solve the interaction (and would receive a rating of 0).
    /// The precondition is a simple check whether the player passes through the left and right hole bounds.
    func precondition(forValidSolution solution: Solution) -> Bool {
        // Left side. Approximate via center (just requiring 1 instead of 2 height calculations)
        let leftSide = interaction.holeMovement.intersectionsWithBoundsCurves.left
        let leftHeight = solution.height(at: leftSide.xRange.center, for: player, with: jumping)
        if !leftSide.yRange.contains(leftHeight) { return false }

        // Right side (same as above)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        let rightHeight = solution.height(at: rightSide.xRange.center, for: player, with: jumping)
        if !rightSide.yRange.contains(rightHeight) { return false }

        return true
    }

    /// The rating of a given solution – higher is better.
    /// The rating depends on two factors: the tap time rating and the safety rating.
    /// The tap time rating is just the minimum distance between two consecutive jumps; the safety rating rates the player trajectory, i.e. the distance to playfield and bar hole bounds.
    /// These two factors are multiplied. The safety rating is in [0, 1], 0 meaning a definite crash or contact with the playfield bounds (which is bad for player jump tracking and is therefore avoided).
    /// `requiredMinimum` is used as a performance boost: when, during evaluation, it becomes impossible to beat the required minimum rating, terminate evaluation early and return 0.
    func rating(of solution: Solution, requiredMinimum: Double) -> Double {
        // Determine time rating
        let timeDistanceForFirstJump = player.timePassedSinceJumpStart + solution.timeUntilStart
        let allTimeDistances = solution.jumpTimeDistances + [timeDistanceForFirstJump]
        let timeRating = allTimeDistances.min()!

        // Multiply with safety rating
        let requiredSafetyRating = requiredMinimum / timeRating
        return timeRating * safetyRating(of: solution, requiredMinimum: requiredSafetyRating)
    }

    /// The safety rating of a solution, in [0, 1].
    /// 0 if the solution leads to a crash, either into the bar on into the playfield bounds.
    /// `requiredMinimum` is used as a performance boost: when, during evaluation, it becomes impossible to beat the required minimum rating, terminate evaluation early and return 0.
    private func safetyRating(of solution: Solution, requiredMinimum: Double) -> Double {
        if requiredMinimum >= 1 { return 0 }

        // All jumps (starting at current time)
        let firstJump = solution.currentJump(for: player, with: jumping, startingAt: .currentTime)
        let nextJumps = solution.jumps(for: player, with: jumping)
        let allJumps = [firstJump] + nextJumps

        // Calculate safety ratings
        let horizontal = horizontalHoleRating(for: allJumps)
        if horizontal <= requiredMinimum { return 0 } // Shortcut
        let vertical = verticalHoleRating(for: allJumps)
        if vertical <= requiredMinimum { return 0 } // Shortcut
        let playfield = playfieldRating(for: allJumps)

        // Return weakest rating
        return min(horizontal, vertical, playfield)
    }

    /// The rating respective the vertical distance to the bar hole.
    /// Inside [0, 1].
    private func verticalHoleRating(for jumps: [Jump]) -> Double {
        let desiredValue = 30% * interaction.holeMovement.holeSize
        let distance = interaction.holeMovement.distance(to: jumps)
        return min(1, distance / desiredValue)
    }

    /// The rating respective the horizontal distance to the bar hole curve intersections.
    /// Inside [0, 1].
    private func horizontalHoleRating(for jumps: [Jump]) -> Double {
        let desiredValue = 25% * jumping.horizontalJumpLength
        let distance = interaction.holeMovement.intersectionsWithBoundsCurves.distance(to: jumps)
        return min(1, distance / desiredValue)
    }

    /// The rating respective the distance to the playfield bounds.
    /// Inside [0, 1].
    private func playfieldRating(for jumps: [Jump]) -> Double {
        let desiredValue = 20% * playfield.size
        let distance = playfield.distance(to: jumps)
        return min(1, distance / desiredValue)
    }
}

// MARK: Horizontal Jump / Hole Distance

extension PlayerBarInteraction.HoleMovement {
    /// Return the minimal vertical distance from any of the jumps to one of the movement sections.
    /// 0 means there is a crash or touching point.
    func distance(to jumps: [Jump]) -> Double {
        let distances = cartesianMap(jumps, sections) { jump, section in
            section.distance(to: jump)
        }

        return distances.min() ?? .infinity
    }
}

extension PlayerBarInteraction.HoleMovement.Section {
    /// Return the minimal vertical distance to the lower or upper bound.
    /// 0 means there is a crash or touching point.
    func distance(to jump: Jump) -> Double {
        let lowerDistance = lower.distance(to: jump) ?? .infinity
        let upperDistance = upper.distance(to: jump) ?? .infinity
        return min(lowerDistance, upperDistance)
    }
}

extension PlayerBarInteraction.HoleMovement.Section.LinearMovement {
    /// Return the minimal vertical distance in the shared range; if the range is empty, return nil.
    /// 0 means there is a crash or touching point.
    func distance(to jump: Jump) -> Double? {
        // Create common range
        guard let range = range else { return nil }
        let intersection = jump.timeRange.intersection(with: range)
        if intersection.isEmpty { return nil }

        // Find minimal distance
        let lineParabola = Parabola(a: 0, b: line.slope, c: line.intercept)
        let difference = jump.parabola - lineParabola
        return difference.minimalAbsoluteValue(in: intersection)
    }
}

private extension Parabola {
    /// The minimal absolute value in the given range. Only works for parabolas.
    func minimalAbsoluteValue(in range: SimpleRange<Double>) -> Double {
        // Check for a zero
        if let zeroes = QuadraticSolver.solve(self, equals: .zero) {
            if range.contains(zeroes.0) || range.contains(zeroes.1) {
                return 0
            }
        }

        // Parabola is either fully positive or negative inside the range
        return min(abs(minimum(in: range)), abs(maximum(in: range)))
    }

    /// The x value of the apex.
    private var apexXValue: Double {
        -0.5 * b / a
    }

    /// The minimal value the parabola attains in the range.
    func minimum(in range: SimpleRange<Double>) -> Double {
        if range.contains(apexXValue) {
            return min(at(range.lower), at(range.upper), at(apexXValue))
        } else {
            return min(at(range.lower), at(range.upper))
        }
    }

    /// The maximal value the parabola attains in the range.
    func maximum(in range: SimpleRange<Double>) -> Double {
        if range.contains(apexXValue) {
            return max(at(range.lower), at(range.upper), at(apexXValue))
        } else {
            return max(at(range.lower), at(range.upper))
        }
    }
}

// MARK: Vertical Jump / Hole Distance

private extension PlayerBarInteraction.HoleMovement.IntersectionsWithBoundsCurves {
    /// Return the minimal vertical distance from any of the jumps to the left or right intersection curve.
    func distance(to jumps: [Jump]) -> Double {
        // Only look at one or two jumps inside the hole range: one for left and one for right
        let leftJump = jumps.first { !$0.timeRange.intersection(with: left.xRange).isEmpty }
        let rightJump = jumps.last! // Always matches because we set `T = right.xRange.upper` in SolutionGenerator

        // Return minimal distance
        let leftDistance = leftJump.map { left.distance(to: $0, isLeft: true) } ?? .infinity
        let rightDistance = right.distance(to: rightJump, isLeft: false)
        return min(leftDistance, rightDistance)
    }
}

private extension PlayerBarInteraction.HoleMovement.IntersectionsWithBoundsCurves.IntersectionWithBoundsCurve {
    /// Return the minimal horizontal distance from the jump to the upper or lower line y = const.
    func distance(to jump: Jump, isLeft: Bool) -> Double {
        let lowerDistance = distance(of: jump, to: yRange.lower, guess: isLeft ? xRange.lower : xRange.upper) ?? .infinity
        let upperDistance = distance(of: jump, to: yRange.upper, guess: isLeft ? xRange.upper : xRange.lower) ?? .infinity
        return min(lowerDistance, upperDistance)
    }

    /// The horizontal distance to a point (guess, const)
    private func distance(of jump: Jump, to const: Double, guess: Double) -> Double? {
        guard let solution = QuadraticSolver.solve(jump.parabola, equals: const, solutionNearestToGuess: guess) else { return nil }
        return abs(solution - guess)
    }
}

// MARK: Jump / Playfield Distance

private extension PlayfieldProperties {
    /// Return the minimal vertical distance from any of the jumps to the playfield bounds (lower and upper).
    /// 0 means there is a intersection or touching point.
    func distance(to jumps: [Jump]) -> Double {
        jumps.map(distance(to:)).min() ?? .infinity
    }

    /// Return the minimal vertical distance from the jump to the playfield bounds (lower and upper).
    /// 0 means there is a intersection or touching point.
    private func distance(to jump: Jump) -> Double {
        let lower = jump.parabola.minimum(in: jump.timeRange)
        let lowerDistance = lower - lowerRadius
        if lowerDistance <= 0 { return 0 }

        let upper = jump.parabola.maximum(in: jump.timeRange)
        let upperDistance = 2 * (upperRadius - upper) // Top is less dangerous than bottom
        if upperDistance <= 0 { return 0 }

        return min(lowerDistance, upperDistance)
    }
}
