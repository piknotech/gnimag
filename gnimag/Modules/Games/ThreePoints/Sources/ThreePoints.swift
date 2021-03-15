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
        if let result = imageAnalyzer.analyze(image: image) {
            gameModelCollector.accept(result: result, time: time)
            tapPredictor.predictionStep()
        }
    }

    /// Initialize the imageAnalyzer on the very first image.
    /// Does nothing if imageAnalyzer is already initialized.
    internal func performFirstImageSetupIfRequired(with image: Image) {
        guard !imageAnalyzer.isInitialized else { return }

        playfield = imageAnalyzer.initialize(with: image)
        tapPredictor = TapPredictor(playfield: playfield, tapper: tapper, timeProvider: imageProvider.timeProvider)
        guard playfield != nil else {
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }
    }
}
