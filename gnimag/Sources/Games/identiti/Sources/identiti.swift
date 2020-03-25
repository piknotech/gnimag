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
    private let imageProvider: ImageProvider
    private let tapper: Tapper

    private let imageAnalyzer: ImageAnalyzer
    
    /// The queue where image analysis is performed on.
    private var queue: GameQueue!

    /// The current/latest exercise.
    /// Because images are analysed each frame, currentExercise is stored and compared with newly analyzed images until a different exercise is detected.
    private var currentExercise: Exercise?

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: Tapper) {
        self.imageProvider = imageProvider
        self.tapper = tapper

        imageAnalyzer = ImageAnalyzer()
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
        // Initialize imageAnalyzer on first image
        if !imageAnalyzer.isInitialized {
            let success = imageAnalyzer.initializeWithFirstImage(image)
            if !success {
                exit(withMessage: "First image could not be analyzed! Aborting.")
            }
        }

        // Analyze and process image
        guard let exercise = imageAnalyzer.analyze(image: image), exercise != currentExercise else { return }
        print(exercise)
        currentExercise = exercise
    }
}
