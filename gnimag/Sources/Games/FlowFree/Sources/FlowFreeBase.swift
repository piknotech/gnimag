//
//  Created by David Knothe on 01.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit
import Image
import ImageAnalysisKit
import Tapping

/// FlowFreeBase bundles common functionality of different FlowFree game modes.
public class FlowFreeBase {
    private let imageAnalyzer: ImageAnalyzer
    internal let pathTracer: PathTracer

    /// The queue where image analysis is performed on.
    internal private(set) var queue: GameQueue!
    internal let onOffImageProvider: OnOffImageProvider

    /// The stream of incoming levels.
    private var levelStream = ValueStreamDamper<Level>(numberOfConsecutiveValues: 1)

    /// Default initializer.
    public init(imageProvider: ImageProvider, dragger: Dragger) {
        imageAnalyzer = ImageAnalyzer()
        pathTracer = PathTracer(underlyingDragger: dragger)

        onOffImageProvider = OnOffImageProvider(wrapping: imageProvider)
        queue = GameQueue(imageProvider: onOffImageProvider, synchronousFrameCallback: update)

        // Level detection callback
        levelStream.newValue += { level in
            if let level = level, level.targets.count > 0 {
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
        guard performFirstImageSetupIfRequired(with: image) else { return }

        let level = imageAnalyzer.analyze(image: image)
        levelStream.add(value: level) // Also add nil-levels -> allows to (manually) repeat a level
    }

    /// Initialize the imageAnalyzer and pathTracer on the very first image.
    /// Does nothing if imageAnalyzer is already initialized.
    /// Return false if the imageAnalyzer couldn't be initialized.
    private func performFirstImageSetupIfRequired(with image: Image) -> Bool {
        guard !imageAnalyzer.isInitialized else { return true }

        let success = imageAnalyzer.initialize(with: image)
        if !success { return false } // Do not exit, just return false; initialization will be retried each frame

        // Share screen layout with pathTracer
        pathTracer.screen = imageAnalyzer.screen

        return true
    }

    /// Called from the levelStream when it detects a new level.
    /// Override to perform custom logic.
    internal func newLevelDetected(level: Level) {
    }
}
