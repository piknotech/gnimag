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

    /// Convert the current jump of the player into a Jump; the jump ends after currentTime + `timeUntilStart`.
    /// A time of 0 represents the current time.
    func currentJump(for player: PlayerProperties, with properties: JumpingProperties) -> Jump {
        let jumpStart = Point(time: -player.timePassedSinceJumpStart, height: player.lastJumpStart.y)
        return Jump.from(startPoint: jumpStart, duration: player.timePassedSinceJumpStart + timeUntilStart, jumping: properties)
    }

    /// Convert the jump time distances into actual Jumps, starting at the current player position.
    /// This does NOT include the current jump of the player; retrieve it via `currentJump(for:with:)`.
    /// A time of 0 represents the current time.
    func jumps(for player: PlayerProperties, with properties: JumpingProperties) -> [Jump] {
        let currentJump = self.currentJump(for: player, with: properties)
        return Jump.jumps(forTimeDistances: jumpTimeDistances, timeUntilEnd: timeUntilEnd, startPoint: currentJump.endPoint, jumping: properties)
    }

    /// Convert this sequence to a TapSequence.
    func asTapSequence(relativeTo currentTime: Double) -> TapSequence {
        let tapTimes = jumpTimeDistances.scan(initial: currentTime + timeUntilStart, +) // Never empty
        let unlockTime = tapTimes.last! + timeUntilEnd
        return TapSequence(tapTimes: tapTimes, unlockTime: unlockTime)
    }
}
