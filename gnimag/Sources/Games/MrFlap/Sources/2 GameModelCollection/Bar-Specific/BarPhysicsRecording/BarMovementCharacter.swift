//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// BarMovementCharacter enumerates the different options of bar movement during a MrFlap game.
/// In normal mode, there is only a single character: the bars are thin and move slowly.
/// In hard mode, there are two characters which change every three points.
enum BarMovementCharacter {
    case normal
    case hardFast // Fast movement, thick bars
    case hardMany // Many, thin, slower moving bars

    init(gameMode: GameMode, points: Int) {
        switch gameMode {
        case .normal:
            self = .normal

        case .hard:
            self = (points / 3).isMultiple(of: 2) ? .hardFast : .hardMany
        }
    }
}
