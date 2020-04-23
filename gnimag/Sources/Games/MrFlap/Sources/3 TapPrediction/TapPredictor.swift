//
//  Created by David Knothe on 26.12.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import Geometry
import Image
import LoggingKit
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

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.TapPrediction { debugLogger.currentFrame.tapPrediction }

    /// Only perform one "strategy switch" logging call per bar.
    private var loggingDamper = ActionStreamDamper(delay: .infinity, performFirstActionImmediately: true)

    /// A class storing all recently passed bars, for debugging.
    private let interactionRecorder = InteractionRecorder(maximumStoredInteractions: 50)

    /// Information about the most recent solution, for debugging.
    /// Thereby, the most recent solution can either be the result from the current frame or from a previous frame.
    private var mostRecentSolution: MostRecentSolution?
    struct MostRecentSolution {
        /// The original solution. `referenceTime` corresponds to 0.
        let solution: InteractionSolutionStrategy.Solution
        var referenceTime: Double { associatedPredictionFrame.currentTime }

        /// The prediction frame that was used for calculating the solution.
        let associatedPredictionFrame: PredictionFrame
    }

    /// Default initializer.
    init(tapper: SomewhereTapper, timeProvider: TimeProvider, debugLogger: DebugLogger) {
        strategies = Strategies(
            idle: IdleStrategy(relativeIdleHeight: 0.5, minimumJumpDistance: 0.2), // ...?
            singleBar: OptimalSolutionViaRandomizedSearchStrategy(minimumJumpDistance: 0.2)
        )

        self.debugLogger = debugLogger
        super.init(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: .absolute(0.05)) // ...?

        // Re-allow logging "strategy switch" once interaction changes
        interactionRecorder.interactionCompleted += {
            self.loggingDamper.reset()
        }
    }

    /// Set the game model. Only call this once.
    /// Call once the game model collector is ready and has a GameModel object.
    func set(gameModel: GameModel) {
        precondition(self.gameModel == nil)
        self.gameModel = gameModel

        // Link player jump for tap delay detection
        gameModel.player.linkPlayerJump(to: self)
    }

    /// Remove all scheduled taps.
    func removeScheduledTaps() {
        scheduler.unscheduleAll()
    }

    /// Calculate AnalysisHints for the given time, i.e. predict where the player will be located at the given (future) time.
    func analysisHints(for time: Double) -> AnalysisHints? {
        let expectedDetectionTimes = scheduler.allExpectedDetectionTimes.filter { $0 <= time }

        guard
            let model = gameModel,
            let playerSize = model.player.size.average,
            let jumping = JumpingProperties(player: model.player),
            let player = PlayerProperties(player: model.player, jumping: jumping, performedTapTimes: expectedDetectionTimes, currentTime: time) else { return nil }

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
        guard let model = gameModel, let delay = scheduler.delay else { return nil }
        let currentTime = timeProvider.currentTime + delay
        guard let frame = PredictionFrame.from(model: model, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: currentTime, maxBars: 1) else { return nil }

        // Debug logging
        performDebugLogging(with: model, frame: frame, delay: delay)

        // Choose and apply strategy
        let strategy = self.strategy(for: frame)
        var solution: InteractionSolutionStrategy.Solution

        if let directSolution = strategy.solution(for: frame) {
            solution = directSolution
        } else {
            // Fallback strategy
            solution = strategies.idle.solution(for: frame)!
            debug.fellBackToIdleStrategy = true

            loggingDamper.perform {
                Terminal.log(.warning, "TapPredictor – didn't find a solution with the preferred strategy, falling back to IdleStrategy (predictionTime: \(frame.currentTime)).")
            }
        }

        // Debug-store solution
        mostRecentSolution = MostRecentSolution(solution: solution, associatedPredictionFrame: frame)

        return solution.convertToRelativeTapSequence(currentTime: currentTime, player: frame.player, jumping: frame.jumping)
    }

    /// Called after each frame, no matter whether predictionLogic was called or not.
    override func frameFinished(hasPredicted: Bool) {
        debug.wasPerformed = hasPredicted
        debug.scheduledTaps = scheduler.scheduledTaps
        debug.executedTaps = scheduler.performedTaps
        debug.wasLocked = !hasPredicted
        debug.isLocked = lockIsActive
        debug.mostRecentSolution = mostRecentSolution

        // Create PredictionFrame just for debug logging if required
        if !hasPredicted {
            guard let model = gameModel, let delay = scheduler.delay else { return }
            let currentTime = timeProvider.currentTime + delay
            guard let frame = PredictionFrame.from(model: model, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: currentTime, maxBars: 1) else { return }

            performDebugLogging(with: model, frame: frame, delay: delay)
        }
    }

    /// Write information about the tap prediction frame into the current debug logger frame.
    private func performDebugLogging(with model: GameModel, frame: PredictionFrame, delay: Double) {
        debug.delay = delay
        debug.frame = frame
        debug.realTimeDuringTapPrediction = frame.currentTime - delay // = timeProvider.currentTime
        debug.playerHeight.from(tracker: model.player.height)
        debug.playerAngleConverter = PlayerAngleConverter(player: model.player)
        debug.interactionRecorder = interactionRecorder

        frame.bars.first.map(interactionRecorder.add(interaction:))

        debug.delayValues.from(tracker: scheduler.delayTracker.tracker)
        debug.gravityValues.from(tracker: model.player.height.debug.gravityTracker)
        debug.jumpVelocityValues.from(tracker: model.player.height.debug.jumpVelocityTracker)
    }

    /// Choose the strategy to calculate the solution for a given frame.
    private func strategy(for frame: PredictionFrame) -> InteractionSolutionStrategy {
        if frame.bars.count == 0 {
            return strategies.idle
        }

        guard let numTaps = strategies.singleBar.minimumNumberOfTaps(for: frame) else {
            Terminal.log(.error, "TapPredictor – it is impossible to solve the current frame, going to crash.")
            return strategies.idle
        }

        if numTaps > 5 { // 6 or more taps - singleBarStrategy yields weird results
            return strategies.idle
        } else {
            return strategies.singleBar
        }
    }

    /// Check if a prediction lock should be applied.
    override func shouldLock(scheduledSequence: RelativeTapSequence) -> Bool {
        guard let nextTap = scheduledSequence.nextTap, let referenceTime = referenceTimeForTapSequence else {
            return true // When sequence is empty, lock and wait until the sequence unlocks (via unlockDuration)
        }

        // Get relative duration from now
        let referenceShift = timeProvider.currentTime - referenceTime
        let time = nextTap.relativeTime - referenceShift

        return time < 0.05
    }
}
