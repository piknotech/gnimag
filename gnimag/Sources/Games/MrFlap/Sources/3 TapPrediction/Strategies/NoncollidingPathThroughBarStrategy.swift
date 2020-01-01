//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A NoncollidingPathThroughBarStrategy calculates a jumping strategy (i.e. a series of jumps) that will lead a player through a given bar.
/// This strategy also suggests a starting point from where the jump sequence must start.
/// This means, this strategy DOES NOT take the current position or velocity of the player into account – it is only concerned with the final passing of the bar, avoiding crashes.
protocol NoncollidingPathThroughBarStrategy {
    /// Calculate the jump sequence.
    /// You do not need to take the current player position into account.
    func jumpSequence(through bar: BarProperties, in playfield: PlayfieldProperties, with player: PlayerProperties, jumpProperties: JumpingProperties) -> JumpSequenceWithStartingPoint
}

/// A jump sequence defined by the starting point of the first jump and the time distances for the following jump starts.
struct JumpSequenceWithStartingPoint {
    /// The starting point.
    let start: CGPoint

    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]
}
