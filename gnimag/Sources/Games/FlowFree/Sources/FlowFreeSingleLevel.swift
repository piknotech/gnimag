//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import Image
import ImageAnalysisKit

/// FlowFreeSingleGame plays one single level of Flow Free.
public class FlowFreeSingleLevel {
    /// The queue where image analysis is performed on.
    private var queue: GameQueue!

    /// The stream of incoming levels.
    /// This is used to filter out image analysis errors: instead of immediately solving and playing the first incoming image, we require 3 consecutive frames to yield the same level. This precludes single-frame image errors.
    private var levelStream = ValueStreamDamper<Level>(numberOfConsecutiveValues: 3)

    /// Default initializer.
    public init(imageProvider: ImageProvider) {
        let wrappedProvider = OnOffImageProvider(wrapping: imageProvider)
        queue = GameQueue(imageProvider: wrappedProvider, synchronousFrameCallback: update)
    }

    /// Begin receiving images and play the game.
    /// Only call this once.
    public func play() {
        queue.begin()
    }

    /// Update method, called each time a new image is available.
    private func update(image: Image, time: Double) {
    }
}
