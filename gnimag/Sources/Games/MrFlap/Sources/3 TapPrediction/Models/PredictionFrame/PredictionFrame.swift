//
//  Created by David Knothe on 06.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// PredictionFrame bundles all properties (i.e. simplified models) that are relevant for a single frame of tap prediction.
struct PredictionFrame {
    let bars: [PlayerBarInteraction]

    let player: PlayerProperties
    let playfield: PlayfieldProperties
    let jumping: JumpingProperties
    let currentTime: Double
}

// MARK: Conversion

extension PredictionFrame {
    /// Convert a GameModel into a PredictionFrame.
    static func from(model: GameModel, performedTapTimes: [Double], currentTime: Double, maxBars: Int) -> PredictionFrame? {
        guard
            let jumping = JumpingProperties(player: model.player),
            let player = PlayerProperties(player: model.player, jumping: jumping, performedTapTimes: performedTapTimes, currentTime: currentTime),
            let playfield = PlayfieldProperties(playfield: model.playfield, with: model.player) else { return nil }

        let bars = Array(convertBars(model: model, player: player, playfield: playfield, currentTime: currentTime).prefix(maxBars))

        return PredictionFrame(bars: bars, player: player, playfield: playfield, jumping: jumping, currentTime: currentTime)
    }

    /// Convert all bars to PlayerBarInteractions, sorted by their directed distance from the player.
    private static func convertBars(model: GameModel, player: PlayerProperties, playfield: PlayfieldProperties, currentTime: Double) -> [PlayerBarInteraction] {
        model.bars.compactMap { tracker in
            if tracker.isDisappearing { return nil }
            guard let bar = BarProperties(bar: tracker, with: model.player, playfield: playfield, currentTime: currentTime) else { return nil }
            return PlayerBarInteraction(player: player, bar: bar, playfield: playfield, currentTime: currentTime, barTracker: tracker)
        }.sorted {
            $0.timeUntilHittingCenter < $1.timeUntilHittingCenter
        }
    }
}
