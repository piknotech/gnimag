//
//  Created by David Knothe on 26.12.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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

    // GameModelCollector is required for guessing the bar movement bounds.
    private var gmc: GameModelCollector?

    /// The strategies which are used to perform the prediction calculation.
    private let strategies: Strategies
    struct Strategies {
        let `default`: InteractionSolutionStrategy

        /// `canSolve(frame:)` must always return true and `solution(for:)` must never return nil.
        let fallback: InteractionSolutionStrategy
    }

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.TapPrediction { debugLogger.currentFrame.tapPrediction }

    /// Only perform one "strategy switch" logging call per bar.
    private var loggingDamper = ActionStreamDamper(delay: .infinity, performFirstActionImmediately: true)

    /// A class storing all recently passed bars, for debugging.
    private let interactionRecorder = InteractionRecorder(maximumStoredInteractions: 50)

    /// Information about the most recent solution.
    /// Thereby, the most recent solution can either be the result from the current frame or from a previous frame.
    private var mostRecentSolution: MostRecentSolution?
    struct MostRecentSolution {
        /// The original solution. `referenceTime` corresponds to 0.
        let solution: Solution
        var referenceTime: Double { associatedPredictionFrame.currentTime }

        /// The strategy that was used for calculating the solution.
        let strategy: InteractionSolutionStrategy

        /// The prediction frame that was used for calculating the solution.
        let associatedPredictionFrame: PredictionFrame
    }

    /// Default initializer.
    init(tapper: SomewhereTapper, timeProvider: TimeProvider, debugLogger: DebugLogger) {
        strategies = Strategies(
            default: OptimalSolutionViaRandomizedSearchStrategy(minimumJumpDistance: 0.2, logger: debugLogger),
            fallback: IdleStrategy(relativeIdleHeight: 0.4, minimumJumpDistance: 0.2)
        )

        self.debugLogger = debugLogger
        super.init(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: .absolute(0.05)) // ...?

        // Re-allow logging "strategy switch" once interaction changes
        interactionRecorder.interactionCompleted += { _ in
            self.loggingDamper.reset()
        }
    }

    /// Set the game model collector and game model. Only call this once.
    /// Call once the game model collector is ready and has a GameModel object.
    func set(gmc: GameModelCollector) {
        precondition(self.gameModel == nil && self.gmc == nil)
        self.gmc = gmc
        self.gameModel = gmc.model

        // Link player jump for tap delay detection
        gmc.model.player.linkPlayerJump(to: self)
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
        guard let gmc = gmc, let model = gameModel, let delay = scheduler.delay else { return nil }
        let currentTime = timeProvider.currentTime + delay
        guard let frame = PredictionFrame.from(gmc: gmc, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: currentTime, maxBars: 2) else { return nil }

        // Debug logging
        performDebugLogging(with: model, frame: frame, delay: delay)

        // Find and store solution
        let (solution, strategy) = self.solution(for: frame)
        mostRecentSolution = MostRecentSolution(solution: solution, strategy: strategy, associatedPredictionFrame: frame)

        return solution.convertToRelativeTapSequence(in: frame)
    }

    /// Called after each frame, no matter whether predictionLogic was called or not.
    override func frameFinished(hasPredicted: Bool) {
        debug.scheduledTaps = scheduler.scheduledTaps
        debug.executedTaps = scheduler.performedTaps
        debug.wasLocked = !hasPredicted
        debug.isLocked = lockIsActive
        debug.mostRecentSolution = mostRecentSolution

        // Create PredictionFrame just for debug logging if required
        if !hasPredicted {
            guard let gmc = gmc, let model = gameModel, let delay = scheduler.delay else { return }
            let currentTime = timeProvider.currentTime + delay
            guard let frame = PredictionFrame.from(gmc: gmc, performedTapTimes: scheduler.allExpectedDetectionTimes, currentTime: currentTime, maxBars: 2) else { return }

            performDebugLogging(with: model, frame: frame, delay: delay)
        }
    }

    /// Write information about the tap prediction frame into the current debug logger frame.
    private func performDebugLogging(with model: GameModel, frame: PredictionFrame, delay: Double) {
        debug.delay = delay
        debug.frame = frame
        debug.playerHeight.from(tracker: model.player.height)
        debug.playerAngleConverter = PlayerAngleConverter(player: model.player)
        debug.interactionRecorder = interactionRecorder

        frame.bars.first.map(interactionRecorder.add(interaction:))

        debug.delayValues.from(tracker: scheduler.delayTracker.tracker)
        debug.gravityValues.from(tracker: model.player.height.debug.gravityTracker)
        debug.jumpVelocityValues.from(tracker: model.player.height.debug.jumpVelocityTracker)
    }

    /// Choose the correct strategy and find a solution for a given frame.
    /// Also, return the strategy that has been used for finding the solution.
    private func solution(for frame: PredictionFrame) -> (Solution, InteractionSolutionStrategy) {
        let (strategy, frame) = self.strategy(for: frame)
        debug.chosenStrategy = type(of: strategy)

        if let solution = strategy.solution(for: frame) {
            return (solution, strategy)
        }
        else {
            // Fallback
            debug.fellBackToIdleStrategy = true
            loggingDamper.perform {
                Terminal.log(.error, "TapPredictor – didn't find a solution with the preferred strategy, falling back to IdleStrategy (predictionTime: \(frame.currentTime)).")
            }

            // this is false: precondition(strategies.fallback.canSolve(frame: frame))
            let solution = strategies.fallback.solution(for: frame)!
            return (solution, strategy)
        }
    }

    /// Choose the correct strategy for a given frame.
    /// Also, modify the frame to remove non-considered interactions and return it.
    private func strategy(for frame: PredictionFrame) -> (InteractionSolutionStrategy, PredictionFrame) {
        var frame = frame

        while !frame.bars.isEmpty {
            if strategies.default.canSolve(frame: frame) {
                return (strategies.default, frame)
            } else {
                frame.bars.removeLast()
            }
        }

        return (strategies.fallback, frame)
    }

    /// Check if a prediction lock should be applied.
    override func shouldLock(scheduledSequence: RelativeTapSequence) -> Bool {
         // When sequence is empty, don't lock
        guard let nextTap = scheduledSequence.nextTap, let referenceTime = referenceTimeForTapSequence else {
            return false
        }

        // Get relative duration from now
        let referenceShift = timeProvider.currentTime - referenceTime
        let time = nextTap.relativeTime - referenceShift

        if let shouldLock = mostRecentSolution?.strategy.shouldLockSolution, shouldLock {
            return time < 0.05
        }

        return false
    }
}
