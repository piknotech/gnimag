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

    /// The stream of exercises which are analyzed each frame.
    /// `exerciseStream` triggers an event when an exercise leaves the screen or when a new exercise comes in.
    private var exerciseStream = ValueStreamDamper<Exercise>(
        numberOfConsecutiveValues: 3,
        numberOfConsecutiveNilValues: 2
    )

    /// The type of OS on which the game is played.
    public enum OSType {
        case android
        case iOS
    }

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: ArbitraryLocationTapper, os: OSType) {
        imageAnalyzer = ImageAnalyzer(os: os)
        buttonTapper = ButtonTapper(underlyingTapper: tapper)
        queue = GameQueue(imageProvider: imageProvider, synchronousFrameCallback: update)

        // Subscrube to exerciseStream event
        exerciseStream.newValue += { exercise in
            if let exercise = exercise { // If exercise is nil, the current exercise left the screen; not interesting
                self.newExerciseDetected(exercise: exercise)
            }
        }
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

        // Get exercise from image; write into stream
        let exercise = imageAnalyzer.analyze(image: image)
        exerciseStream.add(value: exercise)
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

    /// Called from the exerciseStream when it detects a new exercise.
    private func newExerciseDetected(exercise: Exercise) {
        // Tap on correct location
        guard let result = exercise.result else {
            Terminal.log(.error, "No result for exercise \(exercise)!")
            return
        }

        buttonTapper.performTap(for: result)
    }
}
