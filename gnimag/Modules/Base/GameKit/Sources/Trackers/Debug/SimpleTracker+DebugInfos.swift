//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

public extension SimpleTrackerProtocol {
    /// All functions – regression and tolerance bounds.
    var allDebugFunctionInfos: [FunctionDebugInfo] {
        [regressionDebugInfo].compactMap(id) + (toleranceBoundsDebugInfos ?? [])
    }

    /// A FunctionDebugInfo containing the regression function, if existing.
    var regressionDebugInfo: FunctionDebugInfo? {
        regression.map {
            FunctionDebugInfo(function: $0, strokable: scatterStrokable(for: $0), color: .normal, dash: .solid)
        }
    }

    /// Two or more FunctionDebugInfos enclosing the range of values that are valid in respect to the current regression function and tolerance.
    /// Nil if regression is nil.
    var toleranceBoundsDebugInfos: [FunctionDebugInfo]? {
        guard let regression = regression else { return nil }

        var lower, upper: F

        switch tolerance {
        case let .absolute(tolerance):
            lower = regression + (-tolerance)
            upper = regression + tolerance

        case let .absolute2D(dy: dy, dx: dx):
            return functionInfosFor2DTolerance(dx: dx, dy: dy)

        case let .relative(tolerance):
            lower = regression * (1 - tolerance)
            upper = regression * (1 + tolerance)
        }

        return [
            FunctionDebugInfo(function: lower, strokable: scatterStrokable(for: lower), color: .emphasize, dash: .dashed),
            FunctionDebugInfo(function: upper, strokable: scatterStrokable(for: upper), color: .emphasize, dash: .dashed),
        ]
    }

    /// Create 8 functions by shifting the regression in all 45° and 90° directions.
    /// This closely resembles the actual 2D tolerance (where the function would be shifted in all possible directions (360°)).
    private func functionInfosFor2DTolerance(dx: Double, dy: Double) -> [FunctionDebugInfo]? {
        guard let regression = regression else { return nil }

        // Shift function in all 45° and 90° directions (total 8 directions)
        let offsets: [Double] = [-1, 0, 1]
        return (offsets × offsets).compactMap { (x, y) in
            if (x, y) == (0, 0) { return nil }
            let f = regression.shiftedLeft(by: x * dx) + y * dy
            return FunctionDebugInfo(function: f, strokable: scatterStrokable(for: f), color: .emphasize, dash: .dashed)
        }
    }
}
