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
    func jumpSequenceThroughNextBar(model: GameModel, performedTaps: [Double], currentTime: Double) -> JumpSequenceFromCurrentPosition? {
        // Convert models
        guard
            let jump = JumpingProperties.from(player: model.player),
            let player = PlayerProperties.from(player: model.player, jumping: jump, performedTaps: performedTaps, currentTime: currentTime),
            let playfield = PlayfieldProperties.from(playfield: model.playfield, with: model.player) else { return nil }

        // Perform strategies
        let pathThroughBar = noncollidingPathThroughBarStrategy.jumpSequence(through: bar, in: playfield, with: player, jumpProperties: jump)

        let pathToStartingPoint = wayToSpecificPointStrategy.jumpSequence(to: pathThroughBar.startingPoint, in: playfield, with: player, jumpProperties: jump)

        // Concatenate sequences
        return concatenate(sequence1: pathToStartingPoint, sequence2: pathThroughBar)
    }

    /// Find the next bar following the current player position (at `currentTime`).
    private func nextBar(model: GameModel, player: PlayerProperties, playfield: PlayfieldProperties, currentTime: Double) -> BarProperties? {
        let bars = model.bars.compactMap { course in
            BarProperties.from(bar: course, with: model.player, playfield: playfield, currentTime: currentTime)
        }

        // Calculate directed distance from player to each bar
        let angularDistances = bars.map { bar -> Double in
            let speed = player.xSpeed - bar.xSpeed
            return player.currentPosition.x.directedDistance(to: bar.xPosition, direction: speed)
        }

        // Return nearest bar
        let zipped: [(bar: BarProperties, distance: Double)] = Array(zip(bars, angularDistances))
        return zipped.min { (pair1, pair2) in
            pair1.distance < pair2.distance
        }?.bar
    }

    /// Concatenate two jump sequences.
    private func concatenate(sequence1: JumpSequenceFromCurrentPosition, sequence2: JumpSequenceFromSpecificPosition) -> JumpSequenceFromCurrentPosition {
        let timeDistances1 = sequence1.jumpTimeDistances
        let timeDistances2 = sequence2.jumpTimeDistances.map { $0 + sequence1.timeUntilEnd }

        return JumpSequenceFromCurrentPosition(
            timeUntilStart: sequence1.timeUntilStart,
            jumpTimeDistances: timeDistances1 + timeDistances2,
            timeUntilEnd: sequence2.timeUntilEnd
        )
    }
}
