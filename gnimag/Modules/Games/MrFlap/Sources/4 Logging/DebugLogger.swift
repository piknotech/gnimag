//
//  Created by David Knothe on 29.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
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
    /// This is the last thing which is done by MrFlap.
    func playerHasCrashed() {
        guard parameters.logLastCoupleFramesOnCrash else {
            exit(0)
        }

        queue.cancelAllOperations()

        // Log in background, but with high priority
        queue.qualityOfService = .userInteractive

        self.queue.addOperation {
            for frame in self.lastFrames.elements {
                frame.log(with: self.parameters)
            }
            exit(0)
        }
    }
}
