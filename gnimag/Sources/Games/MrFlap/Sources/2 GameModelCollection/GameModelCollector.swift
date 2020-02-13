//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
class GameModelCollector {
    let model: GameModel

    let barUpdater: BarUpdater

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugLoggerFrame.GameModelCollection { debugLogger.currentFrame.gameModelCollection }

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, mode: GameMode, debugLogger: DebugLogger) {
        model = GameModel(playfield: playfield, initialPlayer: initialPlayer, mode: mode, debugLogger: debugLogger)
        barUpdater = BarUpdater(model: model)

        self.debugLogger = debugLogger
    }

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    func accept(result: AnalysisResult, time: Double) {
        debugLogger.currentFrame.gameModelCollection.wasPerformed = true
        defer { model.player.performDebugLogging() }

        // Update player
        if model.player.integrityCheck(with: result.player, at: time) {
            model.player.update(with: result.player, at: time)
        } else {
            // When the player is not integer, bar tracking cannot proceed correctly
            // TODO: what happens when bar never leaves the appearing state? – detect this!
            print("player not integer (\(result.player))")
            return
        }

        // Update bars
        // Instead of using the game time, use the player angle for bar-related trackers. This is useful to prevent small lags (which stop both the player and the bars) from destroying all of the tracking.
        let playerAngle = model.player.angle.linearify(result.player.angle, at: time) // Map angle from [0, 2pi) to R

        barUpdater.matchAndUpdate(bars: result.bars, time: playerAngle, debugLogger: debugLogger)
    }
}
