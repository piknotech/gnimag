//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
class GameModelCollector {
    let model: GameModel
    let mode: GameMode

    private var barUpdater: BarUpdater!
    let barPhysicsRecorder: BarMovementRecorder

    let points: PointsTracker

    var fineCharacter: FineBarMovementCharacter

    /// When true, the image analyzer will ignore the bars during consecutive image analysis calls.
    var ignoreBars: Bool {
        if case BarCharacterTransitionState.transition = currentTransitionState { return true }
        return false
    }

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.GameModelCollection { debugLogger.currentFrame.gameModelCollection }

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, mode: GameMode, points: PointsTracker, debugLogger: DebugLogger) {
        self.points = points
        self.mode = mode
        model = GameModel(playfield: playfield, initialPlayer: initialPlayer, debugLogger: debugLogger)
        fineCharacter = FineBarMovementCharacter(gameMode: mode, points: points.points)
        barPhysicsRecorder = BarMovementRecorder(playfield: playfield, barCharacter: BarMovementCharacter(from: fineCharacter))

        self.debugLogger = debugLogger

        barUpdater = BarUpdater(gmc: self)
    }

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    /// Returns true if the game model has been updated; else, nothing of the data was integer.
    func accept(result: AnalysisResult, time: Double) -> Bool {
        debugLogger.currentFrame.gameModelCollection.wasPerformed = true
        defer { model.player.performDebugLogging() }

        // Update player
        if model.player.integrityCheck(with: result.player, at: time) {
            model.player.update(with: result.player, at: time)
        } else {
            // When the player is not integer, bar tracking cannot proceed correctly. Still there could be a bar character transition
            processBarCharacterTransition(time: time, player: nil)
            return false
        }

        // Update points tracker and bar physics collector
        points.update(tracker: model.player, time: time)
        fineCharacter = FineBarMovementCharacter(gameMode: mode, points: points.points)
        barPhysicsRecorder.barCharacter = BarMovementCharacter(from: fineCharacter)

        // If there is a bar character transition, perform the necessary steps
        processBarCharacterTransition(time: time, player: result.player)

        // Update bars
        if !ignoreBars {
            // Instead of using the game time, use the player angle for bar-related trackers. This is useful to prevent small lags (which stop both the player and the bars) from destroying all of the tracking.
            let playerAngle = model.player.angle.linearify(result.player.angle, at: time) // Map angle from [0, 2pi) to R
            barUpdater.matchAndUpdate(bars: result.bars, time: playerAngle, debugLogger: debugLogger)
        }

        return true
    }

    // MARK: Bar Character Transitioning
    // When the bar character changes, the old bars are faded out in a small timespan (0.2s) and then new bars appear.

    private var currentTransitionState = BarCharacterTransitionState.noTransition
    private var oldCharacter: FineBarMovementCharacter?
    private let zeroAngle = Angle.north

    /// BarCharacterState indicates in which state of a bar character transition the game model currently is.
    enum BarCharacterTransitionState {
        /// 99% of the time, there is no transition.
        case noTransition

        /// This state will be active while the bars are disappearing (~0.2s).
        /// In this time we do not search for bars in the image.
        case transition(blockingUntilAngle: Angle)
    }

    private func processBarCharacterTransition(time: Double, player: Player?) {
        updateBarCharacterTransitionState(time: time, player: player)
        debug.transitioningState = currentTransitionState

        // When a transition starts, remove all bars from game model
        if case .transition = currentTransitionState {
            let bars = model.bars
            model.bars.removeAll()
            if !bars.isEmpty { model.barsRemoved.trigger(with: bars) }
        }
    }

    /// Update the current bar character transition state.
    /// Use the predicted player angle to CREATE an angle lock, but use the actual player angle (from image analysis) to DISSOLVE the lock.
    private func updateBarCharacterTransitionState(time: Double, player: Player?) {
        defer { oldCharacter = fineCharacter }

        // Check whether transition is happened (using player regression)
        if let old = oldCharacter, old != fineCharacter {
            guard let regression = model.player.angle.regression else { return }
            let endAngle = Angle(zeroAngle.value + 0.2 * regression.slope)
            currentTransitionState = .transition(blockingUntilAngle: endAngle)
        }

        // If a transition is active, check whether it has finished (using the blocking angle and the player from image analysis)
        else if case .transition(blockingUntilAngle: let blockingAngle) = currentTransitionState {
            if let player = player, let direction = model.player.angle.regression?.slope, !Angle(player.angle).isBetween(.north, and: blockingAngle, direction: direction) {
                currentTransitionState = .noTransition
            }

            // This is, unfortunately, an image analysis implementation detail.
            // An alternative would be: use the regression function instead of the actual player. But using the actual player in the image is more robust against lags
            // if let player = model.player.angle.regression, player.at(time) > blockingAngle { ... }
        }
    }
}
