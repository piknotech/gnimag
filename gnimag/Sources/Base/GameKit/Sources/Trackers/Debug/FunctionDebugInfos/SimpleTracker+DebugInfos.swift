//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public extension SimpleTrackerProtocol {
    /// A FunctionDebugInfo containing the regression function, if existing.
    var regressionDebugInfo: FunctionDebugInfo? {
        regression.map {
            FunctionDebugInfo(function: $0, strokable: scatterStrokable(for: $0), color: .normal, dash: .solid)
        }
    }

    /// Two FunctionDebugInfos describing the range of values that are valid in respect to the current regression function and tolerance.
    /// Nil if regression is nil.
    var toleranceBoundsDebugInfos: [FunctionDebugInfo]? {
        guard let regression = regression else { return nil }

        var lower, upper: F

        switch tolerance {
        case let .absolute(tolerance):
            lower = regression + (-tolerance)
            upper = regression + tolerance

        case let .relative(tolerance):
            lower = regression * (1 - tolerance)
            upper = regression * (1 - tolerance)
        }

        return [
            FunctionDebugInfo(function: lower, strokable: scatterStrokable(for: lower), color: .emphasize, dash: .dashed),
            FunctionDebugInfo(function: upper, strokable: scatterStrokable(for: upper), color: .emphasize, dash: .dashed),
        ]
    }
}
