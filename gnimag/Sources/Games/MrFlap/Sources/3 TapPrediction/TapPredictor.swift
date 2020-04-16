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

    /// The strategies which are used to perform the prediction calculation.
    private let strategies: Strategies
    struct Strategies {
        let idle: IdleStrategy
        let singleBar: OptimalSolutionViaRandomizedSearchStrategy
    }

    /// Default initializer.
    init(tapper: SomewhereTapper, timeProvider: TimeProvider) {
        strategies = Strategies(
            idle: IdleStrategy(relativeIdleHeight: 0.5, minimumJumpDistance: 0.1), // ...?
            singleBar: OptimalSolutionViaRandomizedSearchStrategy()
        )

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
        guard
            let model = gameModel,
            let playerSize = model.player.size.average,
            let jumping = JumpingProperties(player: model.player),
            let player = PlayerProperties(player: model.player, jumping: jumping, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: time) else { return nil }

        // Convert predicted values to plain Player
        let position = PolarCoordinates(
            angle: CGFloat(player.currentPosition.x.value),
            height: CGFloat(player.currentPosition.y)
        )

        let expectedPlayer = Player(coords: position, size: playerSize)
        return AnalysisHints(expectedPlayer: expectedPlayer)
    }

    /// Analyze the game model to schedule taps.
    /// Instead of using the current time, input+output delay is added so the calculators can calculate using simulated real-time.
    override func predictionLogic() -> RelativeTapSequence? {
        guard
            let model = gameModel,
            let currentTime = scheduler.delay.map(timeProvider.currentTime.advanced(by:)), // A + B
            let frame = PredictionFrame.from(model: model, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: currentTime, maxBars: 1) else { return nil }

        // Choose and apply strategy
        let strategy = self.strategy(for: frame)

        guard let solution = strategy.solution(for: frame) else { return nil }

        // Debug-draw solution
        if solution.timeUntilStart < 0.1 {
            print("locked! \(solution.timeUntilStart); time: \(timeProvider.currentTime)")
            let now = timeProvider.currentTime
            DispatchQueue.global(qos: .utility).async {
                JumpSequencePlot(frame: frame, solution: solution).writeToDesktop(name: "Plots.noSync/\(now).png")
            }
        }

        return solution.tapSequence
    }

    /// Choose the strategy to calculate the solution for a given frame.
    private func strategy(for frame: PredictionFrame) -> InteractionSolutionStrategy {
        return strategies.idle
        print(frame.bars.count)
        switch frame.bars.count {
        case 0: return strategies.idle
        default: return strategies.singleBar
        }
    }

    /// Check if a prediction lock should be applied.
    override func shouldLock(scheduledSequence: RelativeTapSequence) -> Bool {
         // When the sequence is empty, lock and wait until the sequence unlocks (via unlockDuration)
        guard let time = scheduledSequence.nextTap?.relativeTime else { return true }

        let shouldLock = (time - timeProvider.currentTime) < 0.1
        return shouldLock
    }
}
