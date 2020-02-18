//
//  Created by David Knothe on 26.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import GameKit
import Geometry
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

    /// Calculate AnalysisHints for the given time, i.e. predict where the player will be located at the given (future) time.
    func analysisHints(for time: Double) -> AnalysisHints? {
        guard let actualTapTimes = scheduler.actualTapTimes(before: time) else { return nil }

        guard
            let model = gameModel,
            let playerSize = model.player.size.average,
            let jumping = JumpingProperties(player: model.player),
            let player = PlayerProperties(player: model.player, jumping: jumping, performedTapTimes: actualTapTimes, currentTime: time) else { return nil }

        // Convert predicted values to plain Player
        let position = PolarCoordinates(
            angle: CGFloat(player.currentPosition.x.value),
            height: CGFloat(player.currentPosition.y)
        )

        let expectedPlayer = Player(coords: position, size: playerSize)
        return AnalysisHints(expectedPlayer: expectedPlayer)
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
        guard let actualTapTimes = scheduler.actualTapTimes(before: currentTime) else { return nil }

        guard let sequence = calculator.jumpSequenceThroughNextBar(model: model, performedTapTimes: actualTapTimes, currentTime: currentTime) else { return nil }

        return sequence.asTapSequence(relativeTo: timeProvider.currentTime)
    }

    /// Check if a prediction lock should be applied.
    override func shouldLock(scheduledSequence: TapSequence) -> Bool {
        guard let time = scheduledSequence.nextTapTime else { return true } // When the sequence is empty, wait until the sequence unlocks (via unlockTime)
        return (time - timeProvider.currentTime) < 0.1
    }
}
