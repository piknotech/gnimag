//
//  Created by David Knothe on 20.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Common
import Image
import Tapping

/// Each instance of MrFlap can play a single game of MrFlap.
public class MrFlap {
    private let imageProvider: ImageProvider
    private let tapper: Tapper

    /// The shared playfield.
    private var playfield: Playfield!

    /// The image analyzer.
    private let imageAnalyzer = ImageAnalyzer()
    private var nextHints: AnalysisHints!

    private var gameModelCollector: GameModelCollector!

    /// The current analysis state.
    private var state = State.beforeGame
    enum State {
        case beforeGame
        case waitingForFirstMove(initialPlayerPos: Player)
        case inGame
        case finished
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: Tapper) {
        self.imageProvider = imageProvider
        self.tapper = tapper
    }

    /// Begin receiving images and play the game.
    /// Only call this once.
    /// If you want to play a new game, create a new instance of MrFlap.
    public func play() {
        imageProvider.newImage.subscribe { value in
            self.update(image: value.0, time: value.1)
        }
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
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
    }

    // MARK: State-Specific Update Methods

    /// Analyze the first image to find the playfield. Then tap the screen to start the game.
    private func startGame(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image) else {
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }

        playfield = result.playfield
        gameModelCollector = GameModelCollector(playfield: playfield)
        state = .waitingForFirstMove(initialPlayerPos: result.player)

        tapper.tap()
    }

    /// Check if the first player move, initiated by `startGame`, is visible.
    /// If yes, advance the state to begin collecting game model data.
    private func checkForFirstMove(image: Image, time: Double, initialPlayerPos: Player) {
        guard case let .success(result) = analyze(image: image) else { return }

        if distance(between: result.player, and: initialPlayerPos) > 1 {
            state = .inGame
            gameModelCollector.accept(result: result, time: time) // TODO: remove?
        }
    }

    /// Calculate the pixel distance between two players.
    private func distance(between player1: Player, and player2: Player) -> CGFloat {
        let pos1 = player1.coords.position(respectiveTo: playfield.center)
        let pos2 = player2.coords.position(respectiveTo: playfield.center)
        print(pos1, pos2, pos1.distance(to: pos2))
        return pos1.distance(to: pos2)
    }

    /// Normal update method while in-game.
    private func gameplayUpdate(image: Image, time: Double) {
        guard case let .success(result) = analyze(image: image) else { return }

        gameModelCollector.accept(result: result, time: time)
    }

    // MARK: AnalysisHints

    /// Analyze an image using the ImageAnalyzer and the hints.
    private func analyze(image: Image) -> Result<AnalysisResult, AnalysisError> {
        nextHints ??= initialHints(for: image)
        let result = imageAnalyzer.analyze(image: image, hints: nextHints)

        if case let .success(result) = result {
            updateNextHint(for: result)
        }

        return result
    }

    /// Create the next AnalysisHint for the next call to the ImageAnalyzer.
    private func updateNextHint(for result: AnalysisResult) {
        nextHints = AnalysisHints(expectedPlayerPosition: result.player.coords)
    }

    /// Use approximated default values to create hints for the first image.
    private func initialHints(for image: Image) -> AnalysisHints {
        AnalysisHints(
            expectedPlayerPosition: PolarCoordinates(angle: .pi / 2, height: 0.2 * CGFloat(image.height))
        )
    }
}
