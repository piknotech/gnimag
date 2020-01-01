//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This NoncollidingPathThroughBarStrategy consists only of a single jump.
/// This jump passes the bar in such a way that the minimal distance to the upper hole line and lower hole line for points inside the hole is maximized.
/// This is achieved by creating a parabola x-centered at the bar's x-center, and y-aligned so that the minimal distances to the top and to the bottom are equal.
/// This strategy requires the bar to be thin enough in relation to the jump and player properties – else, a single jump won't be enough to pass the bar without colliding.
struct SingleCenteredJumpThroughBarStrategy: NoncollidingPathThroughBarStrategy {
    func jumpSequence(through bar: BarProperties, in playfield: PlayfieldProperties, with player: PlayerProperties, jumpProperties: JumpingProperties) -> JumpSequenceWithStartingPoint {
        fatalError("todo")
    }
}
