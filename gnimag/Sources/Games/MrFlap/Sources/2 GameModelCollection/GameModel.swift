//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

/// The full, up-to-date model of the running game.
final class GameModel {
    /// The playfield. It does not change during the game and is used to filter out malformed input values.
    let playfield: Playfield

    /// The tracked player object.
    let player: PlayerCourse

    /// All tracked bar objects.
    var bars: [BarCourse]

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, mode: GameMode, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.player = PlayerCourse(playfield: playfield, initialPlayer: initialPlayer, debugLogger: debugLogger)
        self.bars = []

        // Create shared bar movement bound collector
        let guess = guessPercentage(for: mode)
        BarCourse.momventBoundCollector = BarMovementBoundCollector(playfield: playfield, guessPercentage: guess)
    }

    /// The guess percentage for the shared bar movement bound collector, depending on the game mode.
    private func guessPercentage(for mode: GameMode) -> Double {
        switch mode {
        case .normal: return 30%
        case .hard: return 25%
        }
    }
}
