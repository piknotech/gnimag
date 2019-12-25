//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import Geometry
import Image
import TestingTools
import Tapping

/// Each instance of MrFlap can play a single game of MrFlap.
public final class MrFlap {
    private let imageProvider: ImageProvider
    private let tapper: Tapper

    private var queue: GameQueue!

    /// The shared playfield.
    private var playfield: Playfield!

    /// Image analyzer and game model collector.
    private let imageAnalyzer: ImageAnalyzer
    private var gameModelCollector: GameModelCollector!

    private let tapDelayTracker = TapDelayTracker(tolerance: .absolute(10))

    // TODO: remove once using prediction for hints
    private var lastPlayerCoords: PolarCoordinates?

    // The debug logger.
    private let debugLogger: DebugLogger

    /// The current analysis state.
    private var state = State.beforeGame
    enum State {
        case beforeGame
        case waitingForFirstMove(initialPlayerPos: Player)
        case inGame
        case finished
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: Tapper, debugParameters: DebugParameters = .none) {
        self.imageProvider = imageProvider
        self.tapper = tapper

        debugLogger = DebugLogger(parameters: debugParameters)
        imageAnalyzer = ImageAnalyzer(debugLogger: debugLogger)
        queue = GameQueue(imageProvider: imageProvider, synchronousFrameCallback: update)
    }

    /// Begin receiving images and play the game.
    /// Only call this once.
    /// If you want to play a new game, create a new instance of MrFlap.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
        debugLogger.currentFrame.time = time

        // State-specific update
        switch state {
        case .beforeGame:
            startGame(image: image, time: time)

        case let .waitingForFirstMove(initialPlayerPos):
            checkForFirstMove(image: image, time: time, initialPlayerPos: initialPlayerPos)

        case .inGame:
            gameplayUpdate(image: image, time: time)

        case .finished:
            ()
        }

        debugLogger.advance()
    }

    // MARK: State-Specific Update Methods

    /// Analyze the first image to find the playfield. Then tap the screen to start the game.
    private func startGame(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image, time: time) else {
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }

        playfield = result.playfield
        gameModelCollector = GameModelCollector(playfield: playfield, tapDelayTracker: tapDelayTracker, debugLogger: debugLogger)
        state = .waitingForFirstMove(initialPlayerPos: result.player)

        // Tap to begin the game
        tapper.tap()
        tapDelayTracker.tapScheduled(time: imageProvider.time)
    }

    /// Check if the first player move, initiated by `startGame`, is visible.
    /// If yes, advance the state to begin collecting game model data.
    private func checkForFirstMove(image: Image, time: Double, initialPlayerPos: Player) {
        guard case let .success(result) = analyze(image: image, time: time) else { return }

        if distance(between: result.player, and: initialPlayerPos) > 1 {
            state = .inGame
            tapDelayTracker.tapDetected(at: time)
            gameModelCollector.accept(result: result, time: time) // TODO: remove?
        }
    }

    /// Normal update method while in-game.
    private func gameplayUpdate(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image, time: time) else { return }
        gameModelCollector.accept(result: result, time: time)
    }

    /// Calculate the pixel distance between two players.
    private func distance(between player1: Player, and player2: Player) -> CGFloat {
        let pos1 = player1.coords.position(respectiveTo: playfield.center)
        let pos2 = player2.coords.position(respectiveTo: playfield.center)
        return pos1.distance(to: pos2)
    }

    // MARK: Analysis & Hints

    /// Analyze an image using the ImageAnalyzer and the hints.
    private func analyze(image: Image, time: Double) -> Result<AnalysisResult, AnalysisError> {
        let hints = hintsForCurrentFrame(image: image, time: time)
        let result = imageAnalyzer.analyze(image: image, hints: hints)
        debugLogger.currentFrame.hints.hints = hints

        if case let .success(result) = result {
            lastPlayerCoords = result.player.coords
        }

        return result
    }

    /// Calculate the hints for the current image.
    private func hintsForCurrentFrame(image: Image, time: Double) -> AnalysisHints {
        guard let playerSize = gameModelCollector?.model.player.size.average, let playerCoords = lastPlayerCoords else {
            debugLogger.currentFrame.hints.usingInitialHints = true
            return initialHints(for: image)
        }

        let expectedPlayer = Player(
            coords: playerCoords,
            size: playerSize
        )

        return AnalysisHints(expectedPlayer: expectedPlayer)
    }

    /// Use approximated default values to create hints for the first image.
    private func initialHints(for image: Image) -> AnalysisHints {
        let expectedPlayer = Player(
            coords: PolarCoordinates(angle: .pi / 2, height: 0.2 * CGFloat(image.height)),
            size: 0.25 * Double(image.width) // Upper bound
        )
        return AnalysisHints(expectedPlayer: expectedPlayer)
    }
}
