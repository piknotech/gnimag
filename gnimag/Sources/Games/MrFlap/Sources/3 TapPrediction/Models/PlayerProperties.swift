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
    static func from(player: PlayerCourse, currentTime: Double) -> PlayerProperties? {
        guard let converter = PlayerAngleConverter.from(player: player) else { return nil }
        guard let xSpeed = player.angle.tracker.slope else { return nil }

        // Get player's jump start position
        guard let startAngle = player.height.currentSegment.supposedStartTime,
              let startHeight = player.height.currentSegment.tracker.regression?.at(startAngle) else { return nil }
        // TODO 1: else, use information from previous tap scheduling to guess starting time
        // TODO 2: use future jump scheduling (-> nicht current segment sondern evtl. nächstes segment wegen absolviertem tap)

        let startTime = converter.time(from: startAngle)
        let jumpStart = PlayerProperties.JumpStart(x: Angle(startAngle), y: startHeight)

        return PlayerProperties(lastJumpStart: jumpStart, timePassedSinceJumpStart: currentTime - startTime, xSpeed: xSpeed)
    }
}
