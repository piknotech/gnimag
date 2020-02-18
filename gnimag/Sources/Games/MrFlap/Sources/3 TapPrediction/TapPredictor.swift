//
//  Created by David Knothe on 26.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import Image
import Tapping

/// TapPredictor is the main class dealing with tap prediction and scheduling.
class TapPredictor: TapPredictorBase {
    /// The game model object which is continuously being updated by the game model collector.
    private var gameModel: GameModel?

    /// The calculator performing the prediction calculation.
    private let calculator = JumpThroughNextBarCalculator()

    /// Default initializer.
    init(tapper: Tapper, timeProvider: TimeProvider) {
        super.init(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: .absolute(10)) // ...?
    }

    /// Set the game model. Only call this once.
    /// Call once the game model collector is ready and has a GameModel object.
    func set(gameModel: GameModel) {
        precondition(self.gameModel == nil)
        self.gameModel = gameModel

        // Link player jump for tap delay detection
        gameModel.player.linkPlayerJump(to: self)
    }

    /// Call after each successful game model collection to perform tap prediction.
    func predict() {
        predictionStep(predictionLogic: predictionLogic)
    }

    /// Analyze the game model to schedule taps.
    /// Instead of using the current time, input+output delay is added so the calculators can calculate using simulated real-time.
    private func predictionLogic() -> TapSequence? {
        guard let model = gameModel, let delay = scheduler.delay else { return nil }

        let currentTime = timeProvider.currentTime + delay
        guard let sequence = calculator.jumpSequenceThroughNextBar(model: model, performedTapTimes: scheduler.performedTapTimes, currentTime: currentTime) else { return nil }

        return sequence.asTapSequence(relativeTo: timeProvider.currentTime)
    }

    /// Check if a prediction lock should be applied.
    override func shouldLock(scheduledSequence: TapSequence) -> Bool {
        guard let time = scheduledSequence.nextTapTime else { return true } // When the sequence is empty, wait until the sequence unlocks (via unlockTime)
        return (time - timeProvider.currentTime) < 0.1
    }
}
