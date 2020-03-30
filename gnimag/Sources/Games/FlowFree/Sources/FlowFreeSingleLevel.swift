//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit
import Image
import ImageAnalysisKit

/// FlowFreeSingleGame plays one single level of Flow Free.
public class FlowFreeSingleLevel {
    private let imageAnalyzer: ImageAnalyzer

    /// The queue where image analysis is performed on.
    private var queue: GameQueue!

    /// The stream of incoming levels.
    /// This is used to filter out image analysis errors: instead of immediately solving and playing the first incoming image, we require 3 consecutive frames to yield the same level. This precludes single-frame image errors.
    private var levelStream = ValueStreamDamper<Level>(numberOfConsecutiveValues: 3)

    /// Default initializer.
    public init(imageProvider: ImageProvider) {
        imageAnalyzer = ImageAnalyzer()

        let wrappedProvider = OnOffImageProvider(wrapping: imageProvider)
        queue = GameQueue(imageProvider: wrappedProvider, synchronousFrameCallback: update)

        // Level detection callback
        levelStream.newValue += { level in
            if let level = level {
                self.newLevelDetected(level: level)
            }
        }
    }

    /// Begin receiving images and play the game.
    /// Only call this once.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
        guard let level = imageAnalyzer.analyze(image: image) else { return }
        levelStream.add(value: level)
    }

    /// Called from the levelStream when it detects a new level.
    private func newLevelDetected(level: Level) {
        print(level)
    }
}
