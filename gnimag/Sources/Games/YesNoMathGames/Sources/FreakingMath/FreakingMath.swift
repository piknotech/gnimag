//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit
import Image
import ImageAnalysisKit
import Tapping

/// Each instance of FreakingMath can play a single game of FreakingMath.
public final class FreakingMath: GameBase {
    private var freakingMathImageAnalyzer: FreakingMathImageAnalyzer { super.imageAnalyzer as! FreakingMathImageAnalyzer }

    /// Use the score to determine whether a new exercise in on-screen.
    private var lastScore: String?

    /// The game which is played, either Freaking Math or Freaking Math+.
    public enum Game {
        case normal
        case plus
    }
    private let game: Game

    /// Default initializer.
    public init(imageProvider: ImageProvider, tapper: AnywhereTapper, game: Game = .normal) {
        self.game = game

        super.init(
            imageAnalyzer: FreakingMathImageAnalyzer(game: game),
            imageProvider: imageProvider,
            tapper: tapper,
            exerciseStream: ValueStreamDamper(numberOfConsecutiveValues: 2, numberOfConsecutiveNilValues: 1)
        )
    }

    /// Update method, called each time a new image is available.
    override func update(image: Image, time: Double) {
        performFirstImageSetupIfRequired(with: image)

        // Determine whether a new score is on-screen. If so, wait 100ms, then analyze the new exercise.
        guard let score = freakingMathImageAnalyzer.scoreText(of: image) else { return }

        if score == lastScore {
            // Get exercise from image; write into stream
            let exercise = imageAnalyzer.analyze(image: image)
            exerciseStream.add(value: exercise)
        } else {
            lastScore = score
            exerciseStream.add(value: nil) // Clear stream; required if the same equation comes twice

            // Normal game: the equation is fully on-screen only after 100ms
            if game == .normal {
                queue.stop(for: 0.1)
            }
        }
    }
}
