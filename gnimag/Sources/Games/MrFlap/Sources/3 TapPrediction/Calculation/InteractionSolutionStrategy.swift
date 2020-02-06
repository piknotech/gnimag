//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// InteractionSolutionStrategy "solves" a player-bar-interaction in such a way that it provides a tap sequence that allows the player from its current time and position to pass the bar without colliding.
protocol InteractionSolutionStrategy {
    typealias Solution = JumpSequenceFromCurrentPosition
    
    func solution(for interaction: PlayerBarInteraction, on playfield: PlayfieldProperties, player: PlayerProperties, jumping: JumpingProperties, currentTime: Double) -> Solution?
}
