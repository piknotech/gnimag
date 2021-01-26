//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit

/// The full, up-to-date model of the running game.
final class GameModel {
    /// The playfield. It does not change during the game and is used to filter out malformed input values.
    let playfield: Playfield

    /// The tracked player object.
    let player: PlayerTracker

    /// All tracked bar objects.
    var bars: [BarTracker]

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.player = PlayerTracker(playfield: playfield, initialPlayer: initialPlayer, debugLogger: debugLogger)
        self.bars = []
    }
}
