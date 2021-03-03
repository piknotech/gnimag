//
//  Created by David Knothe on 05.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// In contrast to e.g. BarHoleSizeCollector, which has an initial hole size guess but then calculates an average of the actual bar hole sizes, BarCenterSlopeGuesses only provides guesses.
/// Also, a different guess exists for every FineBarMovementCharacter, not just for every BarMovementCharacter.
enum BarCenterSlopeGuesses {
    /// A guess for the value `slope / playfield.fullSize`.
    static func guess(for character: FineBarMovementCharacter) -> Double {
        switch character {
        case .normal(section: 0...2):
            return 5.35%
        case .normal(section: 3):
            return 4.6%
        case .normal(section: 4...5):
            return 3.8%
        case .normal(section: 6):
            return 3.45%

        case .hard(section: 0):
            return 9.55%
        case .hard(section: 1):
            return 34.35%
        case .hard(section: 2):
            return 8.4%
        case .hard(section: 3):
            return 30.5%
        case .hard(section: 4):
            return 7.25%
        case .hard(section: 5):
            return 26.7%
        case .hard(section: 6):
            return 5.35%
        case .hard(section: 7):
            return 22.9%

        default:
            fatalError("Invalid FineBarMovementCharacter")
        }
    }
}
