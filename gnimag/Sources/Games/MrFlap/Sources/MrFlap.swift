//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
    private let tapper: SomewhereTapper

    /// The three great actors – one for each step.
    private let imageAnalyzer: ImageAnalyzer
    private var gameModelCollector: GameModelCollector!
    private let tapPredictor: TapPredictor

    /// The queue where all steps are performed on.
    private var queue: GameQueue!
    private var statsPrinting = ActionStreamDamper(delay: 10, performFirstActionImmediately: false)

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

    /// An Event that is triggered a single time once the player crashes.
    /// Also, when the player crashes, image analysis stops.
    public let crashed = Event<Void>()

    /// The points tracker.
    private let points = PointsTracker()

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: SomewhereTapper, debugParameters: DebugParameters = .none) {
        self.imageProvider = imageProvider
        self.tapper = tapper

        debugLogger = DebugLogger(parameters: debugParameters)
        
        imageAnalyzer = ImageAnalyzer(debugLogger: debugLogger)
        tapPredictor = TapPredictor(tapper: tapper, timeProvider: imageProvider.timeProvider, debugLogger: debugLogger)

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
        
        statsPrinting.perform {
            Terminal.logNewline()
            Terminal.log(.info, self.queue.timingStats.detailedDescription)
            Terminal.logNewline()
        }
    }

    // MARK: State-Specific Update Methods

    /// Analyze the first image to find the playfield. Then tap the screen to start the game.
    private func startGame(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image, time: time) else {
            debugLogger.logSynchronously(force: true)
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }

        // Fill properties from first analyzed image
        state = .waitingForFirstMove(initialPlayerPos: result.player)
        playfield = result.playfield
        gameModelCollector = GameModelCollector(playfield: playfield, initialPlayer: result.player, mode: result.mode, points: points, debugLogger: debugLogger)
        tapPredictor.set(gmc: gameModelCollector)
        points.setInitialAngle(result.player.angle)

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
            _ = gameModelCollector.accept(result: result, time: time)
        }
    }

    /// Normal update method while in-game.
    /// Perform TapPrediction each frame, i.e. no matter what the outcome of ImageAnalysis and GameModelCollection is.
    private func gameplayUpdate(image: Image, time: Double) {
        switch analyze(image: image, time: time) {
        case let .success(result):
            _ = gameModelCollector.accept(result: result, time: time)
            tapPredictor.predictionStep()

        case .failure(.crashed):
            playerHasCrashed()

        default:
            tapPredictor.predictionStep()
        }
    }

    /// Calculate the pixel distance between two players.
    private func distance(between player1: Player, and player2: Player) -> CGFloat {
        let pos1 = player1.coords.position(respectiveTo: playfield.center)
        let pos2 = player2.coords.position(respectiveTo: playfield.center)
        return pos1.distance(to: pos2)
    }

    /// Called when the player has crashed.
    /// Stops image analysis and performs finalization tasks.
    private func playerHasCrashed() {
        queue.stop()
        tapPredictor.removeScheduledTaps()
        debugLogger.playerHasCrashed()
        crashed.trigger()
    }

    // MARK: Analysis & Hints

    /// Analyze an image using the ImageAnalyzer and the hints.
    private func analyze(image: Image, time: Double) -> Result<AnalysisResult, AnalysisError> {
        let hints = hintsForCurrentFrame(image: image, time: time)
        let result = imageAnalyzer.analyze(image: image, hints: hints)
        debugLogger.currentFrame.hints.hints = hints

        return result
    }

    /// Calculate the hints for the current image.
    private func hintsForCurrentFrame(image: Image, time: Double) -> AnalysisHints {
        tapPredictor.analysisHints(for: time) ?? initialHints(for: image)
    }

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
