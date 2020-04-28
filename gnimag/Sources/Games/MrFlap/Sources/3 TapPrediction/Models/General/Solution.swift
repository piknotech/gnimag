//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

/// A Solution is a wrapper around a RelativeTapSequence.
/// It provides methods to calculate jumps that are performed within this sequence.
/// Thereby, the start position of the solution is given externally, and the solution works relative to this start position.
struct Solution {
    let sequence: RelativeTapSequence

    /// The time distances, between all consecutive jumps.
    /// This includes the time, beginning at zero, until the first jump.
    /// If the sequence consists of 0 jumps, this is empty.
    let jumpTimeDistances: [Double]

    /// The length of the last jump, i.e. the time from the start of the last jump until the jump sequence has finished.
    /// If the sequence consists of 0 jumps, this is the length of the current jump.
    let lengthOfLastJump: Double

    /// The strategy that produced this solution.
    let strategy: InteractionSolutionStrategy.Type

    /// Default initializer.
    init(sequence: RelativeTapSequence, strategy: InteractionSolutionStrategy.Type) {
        self.sequence = sequence
        self.strategy = strategy

        jumpTimeDistances = {
            var result = [Double]()
            var last: Double = 0

            for tap in sequence.taps {
                result.append(tap.relativeTime - last)
                last = tap.relativeTime
            }

            return result
        }()

        lengthOfLastJump = {
            let lastJump = sequence.taps.last?.relativeTime ?? 0
            let unlock = sequence.unlockDuration ?? lastJump
            return unlock - lastJump
        }()
    }

    /// Convenience intializer, implicitly constructing a RelativeTapSequence.
    init(relativeTimes: [Double], unlockDuration: Double?, strategy: InteractionSolutionStrategy.Type) {
        let taps = relativeTimes.map(RelativeTap.init(scheduledIn:))
        self.init(sequence: RelativeTapSequence(taps: taps, unlockDuration: unlockDuration), strategy: strategy)
    }

    /// Annonate all RelativeTaps in the sequence with TapDebugInfos to allow recovering the exactly predicted jumps at a later point in time.
    mutating func annonateTapsWithDebugInfo(for frame: PredictionFrame) {
        for (tap, jump) in zip(sequence.taps, jumps(for: frame.player, with: frame.jumping)) {
            tap.debugInfo = TapDebugInfo(referenceTime: frame.currentTime, jump: jump)
        }
    }

    /// Shift the solution by a given time. This is used to transform a jump sequence from a different frame to the current frame by changing the `timeUntilStart` value.
    /// Use positive `shift` values to transform a jump sequence from a previous frame into the current frame.
    /// If this would render the whole sequence in the past, return nil.
    func shifted(by shift: Double) -> Solution? {
        sequence.shifted(by: shift).map { Solution(sequence: $0, strategy: strategy) }
    }
}

extension Solution {
    /// Values where the current (in-progress) jump of the player should begin when being converted into a Jump.
    enum StartPointForCurrentJump {
        case currentTime // Start at t = 0, at the current player position
        case currentJumpStart // Start at t = -player.timePassedSinceJumpStart, at the current jump start
    }

    /// Convert the current jump of the player into a Jump, either starting at the current time or starting at the actual jump start (which is in the past).
    /// A time of 0 represents the current time.
    func currentJump(for player: PlayerProperties, with properties: JumpingProperties, startingAt startingPoint: StartPointForCurrentJump) -> Jump {
        // Calculate full jump (start at t = -player.timePassedSinceJumpStart)
        let currentJumpDuration = jumpTimeDistances.first ?? lengthOfLastJump
        let startPoint = Point(time: -player.timePassedSinceJumpStart, height: player.currentJumpStart.y)
        let fullJump = Jump.from(startPoint: startPoint, duration: player.timePassedSinceJumpStart + currentJumpDuration, jumping: properties)

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
        // 0 jumps -> empty
        if jumpTimeDistances.isEmpty { return [] }

        let first = currentJump(for: player, with: properties, startingAt: .currentTime)
        return Jump.jumps(forTimeDistances: Array(jumpTimeDistances[1...]), lastJumpDuration: lengthOfLastJump, startPoint: first.endPoint, jumping: properties)
    }

    /// Calculate the height at the given time value.
    /// A time of 0 represents the current time.
    func height(at t: Double, for player: PlayerProperties, with properties: JumpingProperties) -> Double {
        // Shift frame to start at the player's current jump start
        var result = player.currentJumpStart.y
        var remainingTime = t + player.timePassedSinceJumpStart

        // Compute each jump until reaching the required time
        for i in 0 ..< jumpTimeDistances.count {
            // Get duration of current jump
            var jumpDuration = jumpTimeDistances[i]
            if i == 0 {
                jumpDuration += player.timePassedSinceJumpStart
            }

            // Stop when the jump is not fully finished
            if remainingTime < jumpDuration { break }

            // Add full jump
            remainingTime -= jumpDuration
            result += properties.parabola.at(jumpDuration)
        }

        // Add last (partial) jump
        result += properties.parabola.at(remainingTime)
        return result
    }
}
