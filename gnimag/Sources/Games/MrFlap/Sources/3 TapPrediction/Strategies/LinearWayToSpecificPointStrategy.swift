//
//  Created by David Knothe on 01.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This WayToSpecificPointStrategy performs a minimal required amount of jumps to ascend or descend to the required end height level.
/// The distance between all consecutive jumps is the same. This means, each jump contributes the same regarding height ascension or descension.
/// This is an optimal strategy in the following sense: it achieves the maximal possible minimum distance between two consecutive jumps by spacing out all jumps equally.
struct LinearWayToSpecificPointStrategy: WayToSpecificPointStrategy {
    func jumpSequence(to endPoint: Position, in playfield: PlayfieldProperties, with player: PlayerProperties, jumpProperties: JumpingProperties) -> JumpSequenceFromCurrentPosition {

        let xDiff = player.currentPosition.x.directedDistance(to: endPoint.x, direction: player.xSpeed)

        fatalError()
    }
}
