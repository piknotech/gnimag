//
//  Created by David Knothe on 08.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import Image
import Tapping

/// Each instance of ThreePoints can play a single game of ThreePoints.
public final class ThreePoints {
    private let imageProvider: ImageProvider
    private let tapper: SomewhereTapper

    private var queue: GameQueue!
    private let imageAnalyzer = ImageAnalyzer()
    private let gameModelCollector = GameModelCollector()
    private var tapPredictor: TapPredictor!

    private var playfield: Playfield!

    /// The state of the game.
    private var state = State.beforeGame
    private var firstTapTime: Double?
    private var hadInitialChange = false
    private enum State {
        case beforeGame
        case waitingForFirstPrismRotation
        case inGame
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: SomewhereTapper) {
        self.imageProvider = imageProvider
        self.tapper = tapper

        queue = GameQueue(imageProvider: imageProvider, synchronousFrameCallback: update)
    }

    /// Begin receiving images and play the game.
    /// Only call this once. If you want to play a new game, create a new instance of ThreePoints.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
        performFirstImageSetupIfRequired(with: image)

        switch state {
        case .beforeGame:
            beforeGame(image: image, time: time)

        case .waitingForFirstPrismRotation:
            waitingForFirstPrismRotation(image: image, time: time)

        case .inGame:
            inGame(image: image, time: time)
        }
    }

    /// Initialize the imageAnalyzer on the very first image.
    /// Does nothing if imageAnalyzer is already initialized.
    private func performFirstImageSetupIfRequired(with image: Image) {
        guard !imageAnalyzer.isInitialized else { return }

        playfield = imageAnalyzer.initialize(with: image)
        tapPredictor = TapPredictor(playfield: playfield, tapper: tapper, timeProvider: imageProvider.timeProvider, gameModel: gameModelCollector.model)

        guard playfield != nil else {
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }
    }

    /// Tap to start the game. After 1s, determine the delay: tap again and wait until the prism begins rotating.
    private func beforeGame(image: Image, time: Double) {
        tapPredictor.tapNow()
        queue.stop(for: 1) // Don't to anything for 1 sec

        Timing.shared.perform(after: 1) {
            self.firstTapTime = self.imageProvider.timeProvider.currentTime
            self.tapPredictor.tapNow()
        }

        state = .waitingForFirstPrismRotation
    }

    /// Determine whether the prism has changed its rotation. If so, transfer to the in-game state.
    private func waitingForFirstPrismRotation(image: Image, time: Double) {
        guard let result = imageAnalyzer.analyze(image: image) else { return }

        gameModelCollector.accept(result: result, time: time)
        let change = gameModelCollector.model.prism.mostRecentChange

        // On the very first game model collection, there is a change to the current prism top color. Ignore this
        if change != nil && !hadInitialChange {
            hadInitialChange = true
        }

        // The actual change we're interested in is the one from the second tap
        else if change != nil {
            tapPredictor.delay = time - (firstTapTime ?? .infinity)
            state = .inGame
            print("delay:", tapPredictor.delay)

            if tapPredictor.delay < 0 {
                exit(withMessage: "First tap was detected before it was performed!")
            }
        }
    }

    /// Normal in-game update.
    private func inGame(image: Image, time: Double) {
        if let result = imageAnalyzer.analyze(image: image) {
            gameModelCollector.accept(result: result, time: time)
            tapPredictor.predictionStep()
        }
    }
}
