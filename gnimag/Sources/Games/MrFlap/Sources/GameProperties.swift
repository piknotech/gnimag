//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// GameProperties contains hard-coded properties of the game.
/// These properties could be state-specific.
internal enum GameProperties {
    /// States whether the bird moves clockwise.
    static func birdMovesClockwise(in mode: GameMode) -> Bool {
        switch mode {
        case .normal: return true
        case .hard: return false
        }
    }

    /// A guess of what percentage of the playfield free space the bound value for bar direction reversion is.
    /// When the yCenter of a bar reaches this value (in both directions), the bar changes its direction.
    static func barDirectionReversionPercentageGuess(for mode: GameMode) -> Double {
        switch mode {
        case .normal: return 30%
        case .hard: return 25%
        }
    }
}
