//
//  Created by David Knothe on 01.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// A WayToSpecificPointStrategy calculates a jumping strategy (i.e. a series of jumps) that will lead the player from its current position to a specific point.
/// The velocity when hitting the end point is irrelevant.
protocol WayToSpecificPointStrategy {
    /// Calculate the jump sequence to the given (time/height) point.
    func jumpSequence(to endPoint: Point, in playfield: PlayfieldProperties, with player: PlayerProperties, jumping: JumpingProperties, currentTime: Double) -> JumpSequenceFromCurrentPosition
}

/// A jump sequence defined by the time distances for its jump starts.
/// The start position of the jump sequence is given externally.
struct JumpSequenceFromCurrentPosition {
    /// The time from the begin of the sequence to the first jump.
    let timeUntilStart: Double

    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]

    /// The time from the last jump until the jump sequence has finished and fulfilled its purpose.
    let timeUntilEnd: Double

    /// Convert this sequence to a TapSequence.
    func asTapSequence(relativeTo currentTime: Double) -> TapSequence {
        let tapTimes = jumpTimeDistances.scan(initial: currentTime + timeUntilStart, +) // Never empty
        let unlockTime = tapTimes.last! + timeUntilEnd
        return TapSequence(tapTimes: tapTimes, unlockTime: unlockTime)
    }
}
