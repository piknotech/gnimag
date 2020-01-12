//
//  Created by David Knothe on 26.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit
import Image
import Tapping

/// TapPredictor is the main class dealing with tap prediction and scheduling.
/// It acts as a connection between TapPredictionQueue, TapScheduler and the actual prediction calculation (which is performed by `JumpThroughNextBarCalculator`).
class TapPredictor {
    private var queue: TapPredictionQueue!
    private let scheduler: TapScheduler

    /// The image provider, for getting the current time.
    private let imageProvider: ImageProvider

    /// The game model object which is continuously being updated by the game model collector.
    private var gameModel: GameModel?

    /// The calculator performing the prediction calculation.
    private let calculator = JumpThroughNextBarCalculator()

    /// Set the game model. Only call this once.
    /// Call once the game model collector is ready and has a GameModel object.
    func set(gameModel: GameModel) {
        precondition(self.gameModel == nil)
        self.gameModel = gameModel

        // Link player jump to tap delay tracker
        gameModel.player.linkPlayerJump(to: scheduler.delayTracker)
    }

    /// Default initializer.
    init(tapper: Tapper, imageProvider: ImageProvider) {
        self.imageProvider = imageProvider

        scheduler = TapScheduler(tapper: tapper, imageProvider: imageProvider, tapDelayTolerance: .absolute(10)) // ...?
        queue = TapPredictionQueue(interval: 0.1, predictionCallback: predict)
    }

    /// Start the timed prediction queue.
    func begin() {
        queue.start()
    }

    /// Perform a tap immediately.
    /// Use this to perform the initial tap (starting the game).
    func performTap() {
        scheduler.tap()
    }

    /// Call when a tap was just detected.
    /// Use this to complement `performTap`.
    func tapDetected(at time: Double) {
        scheduler.delayTracker.tapDetected(at: time)
    }

    /// Analyze the game model to schedule taps.
    /// Instead of using the current time, input+output delay is added so the calculators can calculate using simulated real-time.
    private func predict() {
        guard let model = gameModel, let delay = scheduler.delay else { return }

        let currentTime = imageProvider.time + delay
        guard let sequence = calculator.jumpSequenceThroughNextBar(model: model, performedTaps: scheduler.performedTaps, currentTime: currentTime) else { return }

        print(sequence)
    }
}
