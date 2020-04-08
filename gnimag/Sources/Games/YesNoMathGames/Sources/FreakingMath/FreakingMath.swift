//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import Image
import ImageAnalysisKit
import Tapping

/// Each instance of FreakingMath can play a single game of FreakingMath.
public final class FreakingMath: GameBase {
    private let imageProvider: OnOffImageProvider
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
    public init(imageProvider: ImageProvider, tapper: ArbitraryLocationTapper, game: Game = .normal) {
        self.imageProvider = OnOffImageProvider(wrapping: imageProvider)
        self.game = game

        super.init(
            imageAnalyzer: FreakingMathImageAnalyzer(game: game),
            imageProvider: self.imageProvider,
            tapper: tapper,
            exerciseStream: ValueStreamDamper(numberOfConsecutiveValues: 2, numberOfConsecutiveNilValues: 1)
        )
    }

    /// Update method, called each time a new image is available.
    override func update(image: Image, time: Double) {
        performFirstImageSetupIfRequired(with: image)

        // Determine whether a new score is on-screen. If so, wait 3 frames, then analyze the new exercise.
        guard let score = freakingMathImageAnalyzer.scoreText(of: image) else { return }

        if score == lastScore {
            // Get exercise from image; write into stream
            let exercise = imageAnalyzer.analyze(image: image)
            exerciseStream.add(value: exercise)
        } else {
            // New score: wait some frames (in normal mode) until equation is fully on-screen
            if game == .normal { imageProvider.ignore(next: 5) }
            lastScore = score
            exerciseStream.add(value: nil) // Clear stream; required if the same equation comes twice
        }
    }
}
