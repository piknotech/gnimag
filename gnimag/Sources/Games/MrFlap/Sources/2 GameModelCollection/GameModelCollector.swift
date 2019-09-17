//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
class GameModelCollector {
    let model: GameModel

    /// Default initializer.
    init(playfield: Playfield) {
        model = GameModel(playfield: playfield)
    }

    /// Use the AnalysisResult to update the game model.
    /// Before updating the game model, check for the integrity of the result.
    func accept(result: AnalysisResult, time: Double) {
        // Update player
        if model.player.integrityCheck(with: result.player, at: time) {
            model.player.update(with: result.player, at: time)
        } else {
            print("player not integer")
        }

        // Match model-bars to tracker-bars
    }
}
