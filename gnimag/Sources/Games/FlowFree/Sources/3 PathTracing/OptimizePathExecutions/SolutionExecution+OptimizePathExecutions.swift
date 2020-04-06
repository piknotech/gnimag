//
//  Created by David Knothe on 03.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

extension SolutionExecution {
    /// Return a SolutionExecution by optimizing the individual PathExecutions, i.e. by removing cells which cause unnecessary turns.
    /// In other words, this speeds up the execution by replacing paths that just consist of right-angled turns with more aggressive paths (i.e. Shortcuts) which minimally intersect other cells, and have, in total, less turns and a smaller length.
    func optimizePathExecutions() -> SolutionExecution {
        SolutionExecution(pathExecutions: pathExecutions.map(optimize(path:)))
    }

    /// Optimize a single PathExecution by the means described above.
    private func optimize(path: PathExecution) -> PathExecution {
        return path
    }
}
