//
//  Created by David Knothe on 01.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A WayToSpecificPointStrategy calculates a jumping strategy (i.e. a series of jumps) that will lead the player from its current position to a specific point.
/// The velocity when hitting the end point is irrelevant.
protocol WayToSpecificPointStrategy {
    /// Calculate the jump sequence to the given point.
    /// The current player position is relevant; you must take it into account.
    func jumpSequence(to endPoint: CGPoint, in playfield: PlayfieldProperties, with player: PlayerProperties, jumpProperties: JumpingProperties) -> JumpSequence
}

/// A jump sequence defined by the time distances for its jump starts.
struct JumpSequence {
    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]

    /// The time from the last jump until the jump sequence has finished and fulfilled its purpose.
    let timeFromLastJumpToSequenceFinish: Double
}
