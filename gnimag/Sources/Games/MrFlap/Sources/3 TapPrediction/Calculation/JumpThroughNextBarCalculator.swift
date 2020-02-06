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
    /// The concrete strategy that is used for jump sequence calculation.
    private let strategy: InteractionSolutionStrategy

    /// Default initializer.
    init() {
        strategy = OptimalSolutionViaRandomizedSearchStrategy()
    }

    /// Calculate the jump sequence through the next bar.
    /// `currentTime` denotes the current time, after adding possible input+output delays.
    /// Returns `nil` if not all tracker regressions are available.
    func jumpSequenceThroughNextBar(model: GameModel, performedTapTimes: [Double], currentTime: Double) -> JumpSequenceFromCurrentPosition? {
        // Convert models
        guard
            let jumping = JumpingProperties(player: model.player),
            let player = PlayerProperties(player: model.player, jumping: jumping, performedTapTimes: performedTapTimes, currentTime: currentTime),
            let playfield = PlayfieldProperties(playfield: model.playfield, with: model.player) else { return nil }

        // Find next bar
        guard let bar = nextBar(model: model, player: player, playfield: playfield, currentTime: currentTime) else { return nil }

        let interaction = PlayerBarInteraction(player: player, bar: bar, playfield: playfield, currentTime: currentTime)
        let frame = PredictionFrame(interaction: interaction, player: player, playfield: playfield, bar: bar, jumping: jumping, currentTime: currentTime)

        return strategy.solution(for: frame)
    }

    /// Find the next bar following the current player position (at `currentTime`).
    private func nextBar(model: GameModel, player: PlayerProperties, playfield: PlayfieldProperties, currentTime: Double) -> BarProperties? {
        let bars = model.bars.compactMap { course in
            BarProperties(bar: course, with: model.player, playfield: playfield, currentTime: currentTime)
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
}
