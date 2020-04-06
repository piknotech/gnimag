//
//  Created by David Knothe on 04.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

extension SolutionExecution {
    /// Remove all intermediate vertices of straight lines (no matter in which direction) of path executions.
    func removeStraightLines() -> SolutionExecution {
        SolutionExecution(pathExecutions: pathExecutions.map(removeStraightLines(from:)))
    }

    /// Remove all intermediate vertices of straight lines (no matter in which direction) from a path execution.
    private func removeStraightLines(from path: PathExecution) -> PathExecution {
        path
    }
}
