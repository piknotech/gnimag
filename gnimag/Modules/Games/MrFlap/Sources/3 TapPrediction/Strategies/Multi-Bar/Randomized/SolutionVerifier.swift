//
//  Created by David Knothe on 31.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit

/// The fine-grained rating of a solution, only for logging.
struct FineGrainedRating {
    let considerFinalJump: Bool
    let meetsPrecondition: Bool
    let total: Double
    let timeRating: Double
    let playfieldRating: Double
    let descendRating: Double
    let horizontalHoleRating: Double
    let verticalHoleRating: Double
}

/// SolutionVerifier assigns a rating to solutions for a given frame.
/// This class considers all bars in the frame.
struct SolutionVerifier {
    let frame: PredictionFrame

    /// Get the fine-grained rating for a solution without using any shortcuts.
    func fineGrainedRating(for solution: Solution, considerFinalJump: Bool) -> FineGrainedRating {
        // All jumps (starting at current time)
        let player = frame.player, jumping = frame.jumping
        let firstJump = solution.currentJump(for: player, with: jumping, startingAt: .currentTime)
        var allJumps = solution.jumps(for: player, with: jumping)
        allJumps.insert(firstJump, at: 0)

        let meetsPrecondition = precondition(forValidSolution: solution)
        let timeRating = self.timeRating(of: solution, considerFinalJump: considerFinalJump)
        let playfield = playfieldRating(for: allJumps)
        let descend = descendRating(for: allJumps)
        let horizontal = horizontalHoleRating(for: allJumps, requiredMinimum: 0)
        let vertical = verticalHoleRating(for: allJumps, requiredMinimum: 0)
        let total = timeRating * playfield * descend * horizontal * vertical

        return FineGrainedRating(considerFinalJump: considerFinalJump, meetsPrecondition: meetsPrecondition, total: total, timeRating: timeRating, playfieldRating: playfield, descendRating: descend, horizontalHoleRating: horizontal, verticalHoleRating: vertical)
    }

    /// Checks if the given solution fulfills a precondition. If not, the solution can immediately be discarded because it will probably not solve the interaction (and would receive a rating of 0).
    /// The precondition is a simple check whether the player passes through the left and right hole bounds.
    func precondition(forValidSolution solution: Solution) -> Bool {
        frame.bars.allSatisfy { bar in
            precondition(for: solution, interaction: bar)
        }
    }

    /// Check whether the precondition is fulfilled for the given interaction.
    private func precondition(for solution: Solution, interaction: PlayerBarInteraction) -> Bool {
        let player = frame.player, jumping = frame.jumping

        // Left side. Attention: we assume the direction of the bounds curve (as it is always shaped like this)
        let leftSide = interaction.holeMovement.intersectionsWithBoundsCurves.left
        if leftSide.xRange.lower > 0 && solution.height(at: leftSide.xRange.lower, for: player, with: jumping) <= leftSide.yRange.lower { return false }
        if leftSide.xRange.upper > 0 && solution.height(at: leftSide.xRange.upper, for: player, with: jumping) >= leftSide.yRange.upper { return false }

        // Right side (same assumptions)
        let rightSide = interaction.holeMovement.intersectionsWithBoundsCurves.right
        if rightSide.xRange.lower > 0 && solution.height(at: rightSide.xRange.lower, for: player, with: jumping) >= rightSide.yRange.upper { return false }
        if rightSide.xRange.upper > 0 && solution.height(at: rightSide.xRange.upper, for: player, with: jumping) <= rightSide.yRange.lower { return false }

        return true
    }

    /// The rating of a given solution – higher is better.
    /// The rating depends on two factors: the tap time rating and the safety rating.
    /// The tap time rating is just the minimum distance between two consecutive jumps; the safety rating rates the player trajectory, i.e. the distance to playfield and bar hole bounds.
    /// These two factors are multiplied. The safety rating is in [0, 1], 0 meaning a definite crash or contact with the playfield bounds (which is bad for player jump tracking and is therefore avoided).
    /// `requiredMinimum` is used as a performance boost: when, during evaluation, it becomes impossible to beat the required minimum rating, terminate evaluation early and return 0.
    func rating(of solution: Solution, requiredMinimum: Double, considerFinalJump: Bool) -> Double {
        let timeRating = self.timeRating(of: solution, considerFinalJump: considerFinalJump)

        // Multiply time rating with safety rating
        let requiredSafetyRating = requiredMinimum / timeRating
        return timeRating * safetyRating(of: solution, requiredMinimum: requiredSafetyRating)
    }

    /// The time rating of a solution, in [0, inf).
    func timeRating(of solution: Solution, considerFinalJump: Bool) -> Double {
        let firstJump = frame.player.timePassedSinceJumpStart + (solution.jumpTimeDistances.first ?? solution.lengthOfLastJump)
        var allTimeDistances = Array(solution.jumpTimeDistances.dropFirst())
        allTimeDistances.append(firstJump)

        let maximumTimeRating = frame.jumping.horizontalJumpLength // Limit time rating to avoid perverse results
        var timeRating = min(maximumTimeRating, allTimeDistances.min()!)

        // If the final jump is very late (i.e. not relevant), penalize the solution
        if considerFinalJump, !solution.relativeTapTimes.isEmpty {
            timeRating = min(timeRating, 3 * solution.lengthOfLastJump)
        }

        return timeRating
    }

    /// The safety rating of a solution, in [0, 1].
    /// 0 if the solution leads to a crash, either into the bar on into the playfield bounds.
    /// `requiredMinimum` is used as a performance boost: when, during evaluation, it becomes impossible to beat the required minimum rating, terminate evaluation early and return 0.
    private func safetyRating(of solution: Solution, requiredMinimum: Double) -> Double {
        let player = frame.player, jumping = frame.jumping

        if requiredMinimum >= 1 { return 0 }

        // All jumps (starting at current time)
        let firstJump = solution.currentJump(for: player, with: jumping, startingAt: .currentTime)
        var allJumps = solution.jumps(for: player, with: jumping)
        allJumps.insert(firstJump, at: 0)

        // Calculate and multiply safety ratings
        var total = 1.0
        for eval in [
            { playfieldRating(for: allJumps) },
            { descendRating(for: allJumps) },
            { horizontalHoleRating(for: allJumps, requiredMinimum: requiredMinimum / total) },
            { verticalHoleRating(for: allJumps, requiredMinimum: requiredMinimum / total) }
        ] {
            // Multiply all ratings together
            total *= eval()
            if total < requiredMinimum { return 0 } // Shortcut
        }

        return total
    }

    /// The rating respective the vertical distance to the bar hole.
    /// Inside [0, 1].
    private func verticalHoleRating(for jumps: [Jump], requiredMinimum: Double) -> Double {
        var rating = 1.0

        for interaction in frame.bars {
            let distance = interaction.holeMovement.distance(to: jumps)
            let desiredValue = 40% * interaction.holeMovement.holeSize
            let score = min(1, distance / desiredValue)
            if score < requiredMinimum { return 0 }
            rating = min(score, rating)
        }

        return rating
    }

    /// The rating respective the horizontal distance to the bar hole curve intersections.
    /// Inside [0, 1].
    private func horizontalHoleRating(for jumps: [Jump], requiredMinimum: Double) -> Double {
        let desiredValue = 25% * frame.jumping.horizontalJumpLength

        var rating = 1.0
        for interaction in frame.bars {
            let distance = interaction.holeMovement.intersectionsWithBoundsCurves.distance(to: jumps)
            let score = min(1, distance / desiredValue)
            if score < requiredMinimum { return 0 }
            rating = min(score, rating)
        }
        return rating
    }

    /// The rating respective the distance to the playfield bounds.
    /// Inside [0, 1].
    private func playfieldRating(for jumps: [Jump]) -> Double {
        let desiredValue = 20% * frame.playfield.size
        let distance = frame.playfield.distance(to: jumps)
        return min(1, distance / desiredValue)
    }

    /// The rating respective the steppest fall. This means, long jumps that fall down a lot and therefore are very steep are discouraged.
    /// Inside [0, 1].
    private func descendRating(for jumps: [Jump]) -> Double {
        let descends = jumps.map { -$0.parabola.derivative(at: $0.endPoint.time) }
        let steepestDescend = ([0.01] + descends).max()!
        let desiredValue = 1.2 * frame.jumping.jumpVelocity
        return min(1, desiredValue / steepestDescend)
    }
}

// MARK: Vertical Jump / Hole Distance

extension PlayerBarInteraction.HoleMovement {
    /// Return the minimal vertical distance from any of the jumps to one of the movement sections.
    /// 0 means there is a crash or touching point.
    func distance(to jumps: [Jump]) -> Double {
        var smallest = Double.infinity

        for jump in jumps {
            for section in sections {
                smallest = min(smallest, section.distance(to: jump))
            }
        }

        return smallest
    }
}

extension PlayerBarInteraction.HoleMovement.Section {
    /// Return the minimal vertical distance to the lower or upper bound.
    /// 0 means there is a crash or touching point.
    func distance(to jump: Jump) -> Double {
        let lowerDistance = lower.distance(to: jump) ?? .infinity
        let upperDistance = (upper.distance(to: jump) ?? .infinity) * 1.5 // Top is less dangerous than bottom
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
    /// The minimal absolute value in the given range.
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

// MARK: Horizontal Jump / Hole Distance

private extension PlayerBarInteraction.HoleMovement.IntersectionsWithBoundsCurves {
    /// Return the minimal vertical distance from any of the jumps to the left or right intersection curve.
    func distance(to jumps: [Jump]) -> Double {
        // Only look at one or two jumps inside the hole range: one for left and one for right
        let leftJump = jumps.first { !$0.timeRange.intersection(with: left.xRange).isEmpty }
        let rightJump = jumps.last { !$0.timeRange.intersection(with: right.xRange).isEmpty }

        // Return minimal distance
        let leftDistance = leftJump.map { left.distance(to: $0, isLeft: true) } ?? .infinity
        let rightDistance = rightJump.map { right.distance(to: $0, isLeft: false) } ?? .infinity
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
        let upperDistance = 3 * (upperRadius - upper) // Top is less dangerous than bottom
        if upperDistance <= 0 { return 0 }

        return min(lowerDistance, upperDistance)
    }
}
