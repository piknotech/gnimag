//
//  Created by David Knothe on 22.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// The full, up-to-date model of the running game.

final class GameModel {
    /// The playfield. It does not change during the game and is used to filter out malformed input values.
    let playfield: Playfield

    /// The tracked player object.
    let player: PlayerCourse

    /// All tracked bar objects.
    let bars: [BarCourse]

    /// Default initializer.
    init(playfield: Playfield) {
        self.playfield = playfield
        self.player = PlayerCourse(playfield: playfield)
        self.bars = []
    }
}
