//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// This InteractionSolutionStrategy finds an optimal solution (respective to a rating method) by intelligently trying a large amount of random tap sequences and choosing the best one.
struct OptimalSolutionViaRandomizedSearchStrategy: InteractionSolutionStrategy {
    func solution(for interaction: PlayerBarInteraction, on playfield: PlayfieldProperties) -> JumpSequenceFromCurrentPosition {
        fatalError()
    }
}
