//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

extension Level {
    /// Try solving a level (synchronously!) using c-flow-solver or the pyflowsolver script.
    /// When an error occurs (i.e. python is not installed), it is logged to the console.
    var solution: Solution? {
        if boardSize <= 12 {
            return CFlowSolver.solve(level: self) ?? PyFlowSolver.solve(level: self)
        } else {
            return PyFlowSolver.solve(level: self)
        }
    }
}
