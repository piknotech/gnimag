//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

/// FlowFreeTimeTrial plays the time trial mode of Flow Free.
public class FlowFreeTimeTrial: FlowFreeBase {
    /// Called from the levelStream when it detects a new level.
    override func newLevelDetected(level: Level) {
        onOffImageProvider.pause() // Pause receiving images until the solution was drawn

        // If solution can't be found, exit (because user probably has to install python etc.)
        guard let solution = level.solution else {
            exit(withMessage: "pyflowsolver couldn't be executed or couldn't find a solution. This may be an image analysis error. Detected level: \(level)")
        }

        pathTracer.draw(solution: solution, to: level)

        // Continue receiving images
        Timing.perform(after: 0.25) {
            self.onOffImageProvider.continue()
        }
    }
}
