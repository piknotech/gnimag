//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// To keep calculations as simple as possible, the player is depicted as a point.
/// Therefore, the playfield and obstacles must be enlarged by the player radius in each direction.
struct PlayerProperties {
    /// Properties describing a jump.
    struct JumpStart {
        let x: Angle
        let y: Double
    }

    /// The position where the last jump started.
    /// Together with the passed time, this gives the exact current player position and velocity.
    let lastJumpStart: JumpStart
    let timePassedSinceJumpStart: Double

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double

    // MARK: Conversion

    /// Convert a player tracker into PlayerProperties.
    static func from(player: PlayerCourse, performedTaps: [Double], currentTime: Double) -> PlayerProperties? {
        guard let converter = PlayerAngleConverter.from(player: player) else { return nil }
        guard let xSpeed = player.angle.tracker.slope else { return nil }

        // Get current jump start
        // TODO: overlapTolerance must be < the minimal distance between two consecutive taps
        let tapTimeAngles = performedTaps.map(converter.angle(from:))
        guard let angularJumpStart = player.height.finalFutureJumpUsingJumpTimes(times: tapTimeAngles, overlapTolerance: 0.05) else { return nil }

        let jumpStart = JumpStart(x: Angle(angularJumpStart.time), y: angularJumpStart.value)
        let jumpStartTime = converter.time(from: angularJumpStart.time)

        return PlayerProperties(lastJumpStart: jumpStart, timePassedSinceJumpStart: currentTime - jumpStartTime, xSpeed: xSpeed)
    }
}
