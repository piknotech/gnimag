//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

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

/// A jump sequence defined by the starting point of the first jump and the time distances for the following jump starts.
struct JumpSequenceFromSpecificPosition {
    /// The (time/height) starting point.
    let startingPoint: Point

    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]

    /// The time from the last jump until the jump sequence has finished and fulfilled its purpose.
    let timeUntilEnd: Double
}
