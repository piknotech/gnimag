//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// FineBarMovementCharacter enumerates all the different options of bar movement during a MrFlap game.
/// This enumeration is very fine. In normal mode, the character changes every 5 points, while in hard mode the character changes every 3 points.
enum FineBarMovementCharacter {
    /// Normal modes. The section is the integral value of the points divided by 5, modulo 7.
    case normal(section: Int)

    /// Hard modes. The section is the integral value of the points divided by 3, modulo 8.
    case hard(section: Int)

    init(gameMode: GameMode, points: Int) {
        switch gameMode {
        case .normal:
            self = .normal(section: Int(points / 5) % 7)

        case .hard:
            self = .hard(section: Int(points / 3) % 8)
        }
    }
}

/// In contrast to FineBarMovementCharacter, BarMovementCharacter has fewer different characters per mode.
/// In normal mode, there is only a single character: the bars are thin and move slowly.
/// In hard mode, there are two characters which change every three points (i.e. every section).
enum BarMovementCharacter {
    case normalBegin // 0 - 19
    case normalEnd // 20 - 34
    case hardFast // Fast movement, thick bars
    case hardMany // Many, thin, slower moving bars

    init(from fineCharacter: FineBarMovementCharacter) {
        switch fineCharacter {
        case .normal(let section):
            self = section < 4 ? .normalBegin : .normalEnd

        case .hard(let section):
            self = section.isMultiple(of: 2) ? .hardFast : .hardMany
        }
    }
}
