//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// A NoncollidingPathThroughBarStrategy calculates a jumping strategy (i.e. a series of jumps) that will lead a player through a given bar.
/// This strategy also suggests a starting point from where the jump sequence must start.
/// This means, this strategy DOES NOT take the exact current position or velocity of the player into account – it is only concerned with the final passing of the bar, avoiding crashes.
protocol NoncollidingPathThroughBarStrategy {
    /// Calculate the jump sequence.
    func jumpSequence(through bar: BarProperties, in playfield: PlayfieldProperties, with player: PlayerProperties, jumpProperties: JumpingProperties) -> JumpSequenceFromSpecificPosition
}

/// A jump sequence defined by the starting point of the first jump and the time distances for the following jump starts.
struct JumpSequenceFromSpecificPosition {
    /// The starting point.
    let startingPoint: Position

    /// The time distances between all consecutive jumps.
    let jumpTimeDistances: [Double]

    /// The time from the last jump until the jump sequence has finished and fulfilled its purpose.
    let timeUntilEnd: Double
}
