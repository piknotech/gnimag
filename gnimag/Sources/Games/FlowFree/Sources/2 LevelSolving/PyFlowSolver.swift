//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import FlowFreeC
import Foundation

/// A wrapper around the pyflowsolver script.
enum PyFlowSolver {
    private static let scriptLocation = NSHomeDirectory() +/ "Library/Application Support/gnimag/FlowFree/pyflowsolver.py"

    /// Try solving a level (synchronously!) using the pyflowsolver script.
    /// When an error occurs (i.e. python is not installed), it is logged to the console.
    static func solve(level: Level) -> Solution? {
        let input = FlowSolverConverter.convertInput(level: level)
        let cmd = "/usr/bin/python \"\(scriptLocation)\" \(input)"

        return cmd.withCString {
            let output = String(cString: execute_cmd($0))

            // Convert output to solution
            guard let result = FlowSolverConverter.convertOutput(string: output, for: level) else {
                Terminal.log(.error, "pyflowsolver didn't run successfully. Output:\n\(output)")
                return nil
            }

            return result
        }
    }
}
