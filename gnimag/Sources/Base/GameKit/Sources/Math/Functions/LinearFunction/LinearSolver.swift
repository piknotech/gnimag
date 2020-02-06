//
//  Created by David Knothe on 06.02.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

public enum LinearSolver {
    /// Solve the equation given by line(x) = 0.
    @_transparent
    public static func zero(of line: LinearFunction) -> Double? {
        if line.slope == 0 { return nil }
        return -line.intercept / line.slope
    }

    /// Solve the equation given by line(x) = value.
    @_transparent
    public static func solve(_ line: LinearFunction, equals value: Double) -> Double? {
        zero(of: line - value)
    }
}
