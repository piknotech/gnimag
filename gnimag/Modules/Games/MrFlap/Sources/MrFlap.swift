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
    private var gameModelCollector: GameModelCollector?
    private var tapPredictor: TapPredictor!

    /// The queue where all steps are performed on.
    private var queue: GameQueue!
    private var statsPrinting = ActionStreamDamper(delay: 10, performFirstActionImmediately: false)

    /// The shared playfield.
    private var playfield: Playfield!

    // The debug logger.
    private let debugLogger: DebugLogger
    private var frame: DebugFrame { debugLogger.currentFrame }

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

    private let lagTracker = InputLagTracker(warningThreshold: 5)

    private let chrono = Chronometer<FramePhase>()

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: SomewhereTapper, debugParameters: DebugParameters = .none) {
        self.imageProvider = imageProvider
        self.tapper = tapper

        debugLogger = DebugLogger(parameters: debugParameters)
        
        imageAnalyzer = ImageAnalyzer(debugLogger: debugLogger)

        let framerateDetector = FramerateDetector()
        queue = GameQueue(imageProvider: imageProvider, synchronousFrameCallback: update, framerateDetector: framerateDetector)

        tapPredictor = TapPredictor(tapper: tapper, timeProvider: imageProvider.timeProvider, debugLogger: debugLogger, framerate: framerateDetector)
    }

    /// Begin receiving images and play the game.
    /// Only call this once. If you want to play a new game, create a new instance of MrFlap.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
        frame.time = time

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

        logFrame()
    }

    /// Perform logging preparation and debug printing for this frame.
    private func logFrame() {
        frame.points = points.points
        let lastFrame = frame

        chrono.measure(.loggingPreparation) {
            debugLogger.advance()
        }

        // Store analysis durations
        lastFrame.analysisDuration = chrono.currentMeasurement(for: .frame)
        lastFrame.loggingPreparationDuration = chrono.currentMeasurement(for: .loggingPreparation)
        lastFrame.imageAnalysis.duration = chrono.currentMeasurement(for: .imageAnalysis)
        lastFrame.gameModelCollection.duration = chrono.currentMeasurement(for: .gameModelCollection)
        lastFrame.tapPrediction.duration = chrono.currentMeasurement(for: .tapPrediction)

        // Print timing statistics every few seconds
        statsPrinting.perform {
            Terminal.logNewline()
            Terminal.log(.info, queue.timingStats.detailedDescription)
            Terminal.logNewline()
            Terminal.log(.info, lagTracker.detailedInformation)
            Terminal.logNewline()

            for phase in FramePhase.allCases {
                let ms = (chrono.averageMeasurement(for: phase) ?? 0) * 1000
                print(String(format: "\(phase) average: %.1f ms", ms))
            }
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
        tapPredictor.set(gmc: gameModelCollector!)
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
            _ = gameModelCollector!.accept(result: result, time: time)
        }
    }

    /// Normal update method while in-game.
    /// Perform TapPrediction each frame, i.e. no matter what the outcome of ImageAnalysis and GameModelCollection is.
    private func gameplayUpdate(image: Image, time: Double) {
        chrono.newFrame()
        chrono.start(.frame)

        let analysis = chrono.measure(.imageAnalysis) {
            analyze(image: image, time: time)
        }

        switch analysis {
        case let .success(result):
            lagTracker.registerFrame(being: .new)

            chrono.measure(.gameModelCollection) {
                gameModelCollector!.accept(result: result, time: time)
            }

            chrono.measure(.tapPrediction) {
                tapPredictor.predictionStep()
            }

        case .failure(.crashed):
            playerHasCrashed()

        case .failure(.samePlayerPosition):
            lagTracker.registerFrame(being: .irrelevant)
            chrono.measure(.tapPrediction) {
                tapPredictor.predictionStep()
            }

        case .failure(.error):
            chrono.measure(.tapPrediction) {
                tapPredictor.predictionStep()
            }
        }

        chrono.stop(.frame)
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
        crashed.trigger()

        Timing.shared.perform(after: 0) { // First log the current frame, then call playerHasCrashed
            self.debugLogger.playerHasCrashed()
        }
    }

    // MARK: Analysis & Hints

    /// Analyze an image using the ImageAnalyzer and the hints.
    private func analyze(image: Image, time: Double) -> Result<AnalysisResult, AnalysisError> {
        let hints = hintsForCurrentFrame(image: image, time: time)
        let ignoreBars = gameModelCollector?.ignoreBars ?? false
        let result = imageAnalyzer.analyze(image: image, hints: hints, ignoreBars: ignoreBars)
        frame.hints.hints = hints

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
