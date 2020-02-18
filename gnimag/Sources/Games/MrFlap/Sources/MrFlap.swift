//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
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

    /// The three great actors – one for each step.
    private let imageAnalyzer: ImageAnalyzer
    private var gameModelCollector: GameModelCollector!
    private let tapPredictor: TapPredictor

    /// The queue where image analysis and game model collection is performed on.
    private var queue: GameQueue!

    /// The shared playfield.
    private var playfield: Playfield!

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
        tapPredictor = TapPredictor(tapper: tapper, timeProvider: imageProvider.timeProvider)

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
            debugLogger.logSynchronously()
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }

        // Fill properties from first analyzed image
        state = .waitingForFirstMove(initialPlayerPos: result.player)
        playfield = result.playfield
        gameModelCollector = GameModelCollector(playfield: playfield, initialPlayer: result.player, mode: result.mode, debugLogger: debugLogger)
        tapPredictor.set(gameModel: gameModelCollector.model)

        // Tap to begin the game
        tapPredictor.tapNow()
    }

    /// Check if the first player move, initiated by `startGame`, is visible.
    /// If yes, advance the state to begin collecting game model data.
    private func checkForFirstMove(image: Image, time: Double, initialPlayerPos: Player) {
        guard case let .success(result) = analyze(image: image, time: time) else { return }

        if distance(between: result.player, and: initialPlayerPos) > 1 {
            state = .inGame
            tapPredictor.tapDetected(at: time)
            gameModelCollector.accept(result: result, time: time) // TODO: remove?
        }
    }

    /// Normal update method while in-game.
    private func gameplayUpdate(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image, time: time) else { return }
        gameModelCollector.accept(result: result, time: time)
        tapPredictor.predict()
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

        // TODO: auf real device: das testen (i.e. ob delay-shift von performedTaps zu actualTaps korrekt ist)
        if case let .success(result) = result {
            //print("h", hints.expectedPlayer)
            //print("r", result.player)
            lastPos = result.player.coords
        }

        return result
    }

    /// Calculate the hints for the current image.
    private func hintsForCurrentFrame(image: Image, time: Double) -> AnalysisHints {
        //tapPredictor.analysisHints(for: time) ?? initialHints(for: image) (TODO)
        if let pos = lastPos {
            return AnalysisHints(expectedPlayer: Player(coords: pos, size: 20))
        } else {
            return initialHints(for: image)
        }
    }

    // TODO: remove
    var lastPos: PolarCoordinates?

    /// Use approximated default values to create hints for the first image.
    private func initialHints(for image: Image) -> AnalysisHints {
        AnalysisHints(
            expectedPlayer: Player(
                coords: PolarCoordinates(angle: .pi / 2, height: 0.2 * CGFloat(image.height)),
                size: 10% * Double(image.width) // Some upper bound
            )
        )
    }
}
