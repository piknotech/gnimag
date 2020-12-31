//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import LoggingKit

final class DebugLogger: LoggingKit.DebugLogger<DebugParameters, DebugFrame> {
    /// A collection of the last 100 frames. When the player crashes, these are logged so the user can find the cause of the crash.
    private var lastFrames = FixedSizeFIFO<DebugFrame>(capacity: 100)

    /// One-time setup: create the logging directory.
    override func setup() {
        if !parameters.isNone {
            createCleanDirectory()
        }
    }

    /// When advancing a frame, save it to the `lastFrames` queue for possible logging on a crash.
    override func advance() {
        if parameters.logLastCoupleFramesOnCrash {
            // Store latest frame and call `prepareSynchronously`
            lastFrames.append(currentFrame)

            if !currentFrame.isValidForLogging(with: parameters) {
                currentFrame.prepareSynchronously(with: parameters)
            }
        }

        super.advance()
    }

    /// Called when the player crashes.
    /// Log the last 100 frames synchronously.
    func playerHasCrashed() {
        if !parameters.logLastCoupleFramesOnCrash { return }

        queue.cancelAllOperations()

        // Log in background, but with high priority
        queue.qualityOfService = .userInteractive

        Timing.shared.perform(after: 0) { // Wait until the current frame has been added to lastFrames
            self.queue.addOperation {
                for frame in self.lastFrames.elements {
                    frame.log(with: self.parameters)
                }
            }
        }
    }
}
