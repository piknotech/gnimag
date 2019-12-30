//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

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
    init(playfield: Playfield, tapDelayTracker: TapDelayTracker, debugLogger: DebugLogger) {
        self.playfield = playfield
        self.player = PlayerCourse(playfield: playfield, tapDelayTracker: tapDelayTracker, debugLogger: debugLogger)
        self.bars = []
    }
}
