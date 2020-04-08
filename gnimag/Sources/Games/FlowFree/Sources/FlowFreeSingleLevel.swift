//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// FlowFreeSingleLevel plays one single level of Flow Free.
public class FlowFreeSingleLevel: FlowFreeBase {
    /// Called from the levelStream when it detects a new level.
    override func newLevelDetected(level: Level) {
        onOffImageProvider.pause() // Stop receiving images
        queue.clear()

        // If solution can't be found, exit (because user probably has to install python etc.)
        guard let solution = level.solution else {
            exit(withMessage: "Couldn't solve level:\n\(Board(level: level))")
        }

        pathTracer.draw(solution: solution, for: level)
        exit(0)
    }
}
