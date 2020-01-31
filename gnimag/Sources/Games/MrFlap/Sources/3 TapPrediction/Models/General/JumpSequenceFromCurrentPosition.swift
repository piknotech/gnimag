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

    /// Calculate the height at the given time value.
    /// A time of 0 represents the current time.
    func height(at t: Double, for player: PlayerProperties, with properties: JumpingProperties) -> Double {
        // Translate everything to start at the player's current jump start
        let t = t + player.timePassedSinceJumpStart
        let allJumps = [player.timePassedSinceJumpStart + timeUntilStart] + jumpTimeDistances
        let cumulated = allJumps.scan(initial: 0, +) // Never empty

        // Find jump we're currently in at time t
        let jumpIndex = cumulated.firstIndex { $0 > t } ?? (cumulated.count - 1) // in 0 ..< count

        // Calculate height of completed jumps and of current one
        let completedJumpsHeight = allJumps[0 ..< jumpIndex].reduce(0) { height, jumpDuration in
            height + properties.parabola.at(jumpDuration)
        }

        let currentJumpDuration = t - cumulated[jumpIndex]
        let currentJumpHeight = properties.parabola.at(currentJumpDuration)

        // Add initial height (from player's current jump start)
        return completedJumpsHeight + currentJumpHeight + player.lastJumpStart.y
    }

    /// Convert this sequence to a TapSequence.
    func asTapSequence(relativeTo currentTime: Double) -> TapSequence {
        let cumulated = jumpTimeDistances.scan(initial: currentTime + timeUntilStart, +) // Never empty
        let unlockTime = cumulated.last! + timeUntilEnd
        return TapSequence(tapTimes: cumulated, unlockTime: unlockTime)
    }
}
