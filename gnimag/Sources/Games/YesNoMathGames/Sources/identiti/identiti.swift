//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import Image
import Tapping

/// Each instance of identiti can play a single game of identiti.
public final class identiti: GameBase {
    /// The type of OS on which the game is played.
    public enum OSType {
        case android
        case iOS
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: AnywhereTapper, os: OSType) {
        super.init(
            imageAnalyzer: identitiImageAnalyzer(os: os),
            imageProvider: imageProvider,
            tapper: tapper,
            exerciseStream: ValueStreamDamper(numberOfConsecutiveValues: 3, numberOfConsecutiveNilValues: 2)
        )
    }
}
