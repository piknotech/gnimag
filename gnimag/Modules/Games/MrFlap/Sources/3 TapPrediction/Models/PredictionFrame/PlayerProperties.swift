//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// To keep calculations as simple as possible, the player is depicted as a point.
/// Therefore, the playfield and obstacles must be enlarged by the player radius in each direction.
struct PlayerProperties {
    /// The position where the current jump started.
    /// Together with the passed time, this gives the exact current player position and velocity.
    let currentJumpStart: Position
    let currentJumpStartPoint: Point // Same as `currentJumpStart`, just using absolute (!) time instead of angle
    let timePassedSinceJumpStart: Double

    /// The current position of the player.
    let currentPosition: Position

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double

    // MARK: Conversion

    /// Create PlayerProperties from the given player tracker.
    init?(player: PlayerTracker, jumping: JumpingProperties, performedTapTimes: [Double], currentTime: Double) {
        guard let converter = PlayerAngleConverter(player: player) else { return nil }
        guard let xSpeed = player.angle.tracker.slope else { return nil }

        self.xSpeed = xSpeed

        // Get current jump start
        // TODO: overlapTolerance must be < the minimal distance between two consecutive taps
        let tapTimeAngles = performedTapTimes.map(converter.angle(from:))
        let timeTolerance = 0.05
        let angularTolerance = converter.angleToTime.slope * timeTolerance
        guard let angularJumpStart = player.height.finalFutureJumpUsingJumpTimes(times: tapTimeAngles, overlapTolerance: angularTolerance) else { return nil }

        currentJumpStart = Position(x: Angle(angularJumpStart.time), y: angularJumpStart.value)
        currentJumpStartPoint = Point(time: converter.time(from: angularJumpStart.time), height: angularJumpStart.value)
        timePassedSinceJumpStart = currentTime - currentJumpStartPoint.time

        // Get current position
        let currentPositionX = currentJumpStart.x.value + xSpeed * timePassedSinceJumpStart
        let currentPositionY = currentJumpStart.y + jumping.parabola.at(timePassedSinceJumpStart)
        currentPosition = Position(x: Angle(currentPositionX), y: currentPositionY)
    }
}
