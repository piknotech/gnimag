//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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
}

extension JumpSequenceFromCurrentPosition {
    /// Values where the current (in-progress) jump of the player should begin when being converted into a Jump.
    enum StartPointForCurrentJump {
        case currentTime // Start at t = 0, at the current player position
        case currentJumpStart // Start at t = -player.timePassedSinceJumpStart, at the current jump start
    }
    /// Convert the current jump of the player into a Jump, either starting at the current time or starting at the actual jump start (which is in the past).
    /// A time of 0 represents the current time.
    func currentJump(for player: PlayerProperties, with properties: JumpingProperties, startingAt startingPoint: StartPointForCurrentJump) -> Jump {
        // Calculate full jump (start at t = -player.timePassedSinceJumpStart)
        let startPoint = Point(time: -player.timePassedSinceJumpStart, height: player.currentJumpStart.y)
        let fullJump = Jump.from(startPoint: startPoint, duration: player.timePassedSinceJumpStart + timeUntilStart, jumping: properties)

        switch startingPoint {
        case .currentTime:
            // Trim fullJump to start at t = 0
            let startPoint = Point(time: 0, height: player.currentPosition.y)
            return Jump(startPoint: startPoint, endPoint: fullJump.endPoint, parabola: fullJump.parabola)

        case .currentJumpStart:
            return fullJump
        }
    }

    /// Convert the jump time distances into actual Jumps, starting at the current player position.
    /// This does NOT include the current jump of the player; retrieve it via `currentJump(for:with:)`.
    /// A time of 0 represents the current time.
    func jumps(for player: PlayerProperties, with properties: JumpingProperties) -> [Jump] {
        let currentJump = self.currentJump(for: player, with: properties, startingAt: .currentTime)
        return Jump.jumps(forTimeDistances: jumpTimeDistances, timeUntilEnd: timeUntilEnd, startPoint: currentJump.endPoint, jumping: properties)
    }

    /// Calculate the height at the given time value.
    /// A time of 0 represents the current time.
    func height(at t: Double, for player: PlayerProperties, with properties: JumpingProperties) -> Double {
        // Shift frame to start at the player's current jump start
        var result = player.currentJumpStart.y
        var remainingTime = t + player.timePassedSinceJumpStart

        // Compute each jump until reaching the required time
        for i in 0 ... jumpTimeDistances.count {
            // Performantly subscript `[firstJumpDuration] + jumpTimeDistances`
            let jumpDuration = (i == 0)
                ? player.timePassedSinceJumpStart + timeUntilStart
                : jumpTimeDistances[i-1]

            // Stop when the jump is not fully finished
            if remainingTime < jumpDuration {
                break
            }

            // Add full jump
            remainingTime -= jumpDuration
            result += properties.parabola.at(jumpDuration)
        }

        // Add last (partial) jump
        result += properties.parabola.at(remainingTime)
        return result
    }

    /// Convert this sequence to a TapSequence.
    func asTapSequence(relativeTo currentTime: Double) -> TapSequence {
        let cumulated = jumpTimeDistances.scan(initial: currentTime + timeUntilStart, +) // Never empty
        let unlockTime = cumulated.last! + timeUntilEnd
        return TapSequence(tapTimes: cumulated, unlockTime: unlockTime)
    }
}
