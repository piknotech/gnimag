//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import Image
import Tapping

/// Each instance of FreakingMath can play a single game of FreakingMath.
public final class FreakingMath: GameBase {
    /// The game which is played, either Freaking Math or Freaking Math+.
    public enum Game {
        case normal
        case plus
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: ArbitraryLocationTapper, game: Game = .normal) {
        super.init(
            imageAnalyzer: FreakingMathImageAnalyzer(game: game),
            imageProvider: imageProvider,
            tapper: tapper,
            exerciseStream: ValueStreamDamper(numberOfConsecutiveValues: 2, numberOfConsecutiveNilValues: 2)
        )
    }
}
