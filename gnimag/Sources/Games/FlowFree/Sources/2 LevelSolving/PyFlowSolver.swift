//
//  Created by David Knothe on 31.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
        let input = Board(level: level).stringify(separator: "#")
        let cmd = "/usr/bin/python \"\(scriptLocation)\" \(input)"

        guard let cOutput = execute_cmd(cmd) else {
            Terminal.log(.error, "pyflowsolver couldn't be executed.")
            return nil
        }
        let output = String(cString: cOutput)

        // Convert output to solution
        guard let board = Board(output), let solution = Solution(board: board, level: level) else {
            Terminal.log(.error, "pyflowsolver didn't run successfully. Output:\n\(output)")
            return nil
        }

        return solution
    }
}
