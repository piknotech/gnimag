//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// To keep calculations as simple as possible, the player is depicted as a point.
/// Therefore, the playfield and obstacles must be enlarged by the player radius in each direction.
struct PlayerProperties {
    /// Properties describing a jump.
    struct JumpStart {
        let x: Double // X in radians.
        let y: Double
        let time: Double
    }

    /// The position and time where the last jump started.
    /// Together with the current time, this gives the exact current player position and velocity.
    let lastJumpStart: JumpStart

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double
}
