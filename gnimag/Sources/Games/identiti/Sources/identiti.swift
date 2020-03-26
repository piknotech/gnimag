//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit
import Image
import Tapping

/// Each instance of identiti can play a single game of identiti.
public final class identiti {
    private let imageAnalyzer: ImageAnalyzer
    private let buttonTapper: ButtonTapper

    /// The queue where image analysis is performed on.
    private var queue: GameQueue!

    /// The current/latest exercise.
    /// Because images are analysed each frame, currentExercise is stored and compared with newly analyzed images until a different exercise is detected.
    private var currentExercise: Exercise?

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: ArbitraryLocationTapper) {
        imageAnalyzer = ImageAnalyzer()
        buttonTapper = ButtonTapper(underlyingTapper: tapper)
        queue = GameQueue(imageProvider: imageProvider, synchronousFrameCallback: update)
    }

    /// Begin receiving images and play the game.
    /// Only call this once.
    /// If you want to play a new game, create a new instance of identiti.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
        performFirstImageSetupIfRequired(with: image)

        // Analyze and process image
        guard let exercise = imageAnalyzer.analyze(image: image), exercise != currentExercise else { return }
        currentExercise = exercise

        // Tap on correct location
        guard let result = exercise.result else {
            Terminal.log(.error, "No result for exercise \(exercise)!")
            return
        }

        buttonTapper.performTap(for: result)
    }

    /// Initialize the imageAnalyzer and buttonTapper on the very first image.
    /// Does nothing if imageAnalyzer is already initialized.
    private func performFirstImageSetupIfRequired(with image: Image) {
        guard !imageAnalyzer.isInitialized else { return }

        let success = imageAnalyzer.initializeWithFirstImage(image)
        if !success {
            exit(withMessage: "First image could not be analyzed! Aborting.")
        }

        // Share screen layout with buttonTapper
        buttonTapper.screen = imageAnalyzer.screen
    }
}
