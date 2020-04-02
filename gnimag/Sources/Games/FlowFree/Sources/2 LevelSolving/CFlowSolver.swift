//
//  Created by David Knothe on 02.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import FlowFreeC

/// A wrapper around the c-flow-solver.
enum CFlowSolver {
    /// Try solving a level (synchronously!) using the c-flow-solver.
    /// When an error occurs, it is (probably) logged to the console.
    static func solve(level: Level) -> Solution? {
        let input = FlowSolverConverter.convertInput(level: level) // TODO: board instead of file

        return input.withCString {
            guard let cOutput = solve_board($0) else {
                Terminal.log(.error, "c-flow-solver output NULL.")
                return nil
            }

            let output = String(cString: cOutput)

            // Convert output to solution
            guard let result = FlowSolverConverter.convertOutput(string: output, for: level) else {
                Terminal.log(.error, "c-flow-solver didn't run successfully. Output:\n\(output)")
                return nil
            }

            return result
        }
    }
}
