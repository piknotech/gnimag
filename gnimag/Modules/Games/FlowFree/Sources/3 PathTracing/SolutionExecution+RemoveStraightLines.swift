//
//  Created by David Knothe on 04.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import ImageAnalysisKit

extension SolutionExecution {
    /// Remove all intermediate vertices of straight lines (no matter in which direction) of path executions.
    func removeStraightLines() -> SolutionExecution {
        SolutionExecution(pathExecutions: pathExecutions.map(removeStraightLines(from:)))
    }

    /// Remove all intermediate vertices of straight lines (no matter in which direction) from a path execution.
    private func removeStraightLines(from path: PathExecution) -> PathExecution {
        var result = path.cells

        var lastDiff: Delta?
        var i = 0

        while i < result.count - 1 {
            let diff = result[i+1] - result[i]
            if diff == lastDiff {
                result.remove(at: i) // Remove and leave i unchanged
            } else {
                lastDiff = diff
                i += 1
            }
        }

        return PathExecution(color: path.color, cells: result)
    }
}
