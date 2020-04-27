//
//  Created by David Knothe on 28.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// InteractionSolutionStrategy "solves" a PredictionFrame in such a way that it provides a tap sequence that allows the player from its current time and position to pass the relevant bar(s) without colliding.
protocol InteractionSolutionStrategy {
    func solution(for frame: PredictionFrame) -> Solution?
}
