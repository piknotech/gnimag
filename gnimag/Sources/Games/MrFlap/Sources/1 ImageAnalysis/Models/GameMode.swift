//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image

/// The GameMode is used to determine specific, hard-coded properties of the game, for example coloring schemes (normal mode = white background, hard mode = black background).
enum GameMode {
    case normal
    case hard

    var birdMovesClockwise: Bool {
        switch self {
        case .normal: return true
        case .hard: return false
        }
    }

    /// Read the game mode from the given coloring, if possible.
    static func from(secondaryColor: Color) -> GameMode? {
        if secondaryColor.distance(to: .white) < 0.1 { return .normal }
        if secondaryColor.distance(to: .black) < 0.1 { return .hard }
        return nil
    }
}
