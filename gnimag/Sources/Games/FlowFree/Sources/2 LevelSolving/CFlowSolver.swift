//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import FlowFreeC

import TestingTools

/// A wrapper around the c-flow-solver.
enum CFlowSolver {
    /// Try solving a level (synchronously!) using the c-flow-solver.
    /// When an error occurs, it is (probably) logged to the console.
    static func solve(level: Level) -> Solution? {
        let input = FlowSolverConverter.convertInput(level: level, for: .c)

        Measurement.begin(id: "c")
        guard let cOutput = solve_board(input) else {
            Terminal.log(.error, "c-flow-solver output NULL.")
            return nil
        }
        Measurement.end(id: "c")

        let output = String(cString: cOutput)

        // Convert output to solution
        guard let result = FlowSolverConverter.convertOutput(string: output, for: level) else {
            Terminal.log(.error, "c-flow-solver didn't run successfully. Output:\n\(output)")
            return nil
        }

        return result
    }
}
