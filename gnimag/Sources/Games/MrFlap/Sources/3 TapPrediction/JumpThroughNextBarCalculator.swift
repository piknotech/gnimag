//
//  Created by David Knothe on 01.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// This type calculates a jump sequence which allows the current player to pass through the next bar.
/// Thereby, it does two things:
///  • Collecting relevant regressions from trackers and converting them into abstract models (`BarProperties`, `JumpingProperties` etc.) Thereby, all obstacles are enlarged to allow treating the player as a single point.
///  • Choosing concrete strategies and using them to perform the actual jump sequence calculations, given the constructed abstract models.
struct JumpThroughNextBarCalculator {
    /// The concrete strategies that are used for jump sequence calculation.
    private let noncollidingPathThroughBarStrategy: NoncollidingPathThroughBarStrategy
    private let wayToSpecificPointStrategy: WayToSpecificPointStrategy

    /// Default initializer.
    init() {
        noncollidingPathThroughBarStrategy = SingleCenteredJumpThroughBarStrategy()
        wayToSpecificPointStrategy = LinearWayToSpecificPointStrategy()
    }

    /// Calculate the jump sequence through the next bar.
    /// `currentTime` denotes the current time, after adding possible input+output delays.
    /// Returns `nil` if not all tracker regressions are available.
    func jumpSequenceThroughNextBar(model: GameModel, performedTaps: [Double], currentTime: Double) -> JumpSequence? {
        // Find next bar
        guard let nextBar = nextBar(model: model, currentTime: currentTime) else { return nil }

        // Convert models
        guard
            let player = PlayerProperties.from(player: model.player, performedTaps: performedTaps, currentTime: currentTime),
            let jump = JumpingProperties.from(player: model.player),
            let bar = BarProperties.from(bar: nextBar, with: model.player, currentTime: currentTime),
            let playfield = PlayfieldProperties.from(playfield: model.playfield, with: model.player) else { return nil }

        // Perform strategies
        let pathThroughBar = noncollidingPathThroughBarStrategy.jumpSequence(through: bar, in: playfield, with: player, jumpProperties: jump)

        let pathToStartingPoint = wayToSpecificPointStrategy.jumpSequence(to: pathThroughBar.start, in: playfield, with: player, jumpProperties: jump)

        // Concatenate sequences
        return concatenate(sequence1: pathToStartingPoint, sequence2: pathThroughBar.sequence)
    }

    /// Find the next bar following the current player position (at `currentTime`).
    private func nextBar(model: GameModel, currentTime: Double) -> BarCourse? {
        // Get player position and running direction
        guard let _playerAngle = model.player.angle.regression?.at(currentTime) else { return nil }
        guard let runningDirection = model.player.angle.tracker.slope else { return nil } // Assumes bars and players do not move in the same direction
        let playerAngle = Angle(_playerAngle)

        // Get bar-angle pairs
        let angles = model.bars.map { $0.angle.regression?.at(currentTime) }
        let barsAndAngles = zip(model.bars, angles)

        // Remove nil-angles
        let validBarsAndAngles: [(bar: BarCourse, angle: Angle)] = barsAndAngles.compactMap { bar, angle in
            guard let angle = angle else { return nil }
            return (bar, Angle(angle))
        }

        // Return bar which is nearest to the player position, in respect to the running direction
        return validBarsAndAngles.min { (pair1, pair2) in
            playerAngle.directedDistance(to: pair1.angle, direction: runningDirection) < playerAngle.directedDistance(to: pair2.angle, direction: runningDirection)
        }?.bar
    }

    /// Concatenate two jump sequences.
    private func concatenate(sequence1: JumpSequence, sequence2: JumpSequence) -> JumpSequence {
        let times1 = sequence1.jumpTimeDistances
        let times2 = sequence2.jumpTimeDistances.map { $0 + sequence1.timeFromLastJumpToSequenceFinish }
        let totalFinishTime = sequence1.timeFromLastJumpToSequenceFinish + sequence2.timeFromLastJumpToSequenceFinish

        return JumpSequence(jumpTimeDistances: times1 + times2, timeFromLastJumpToSequenceFinish: totalFinishTime)
    }
}
