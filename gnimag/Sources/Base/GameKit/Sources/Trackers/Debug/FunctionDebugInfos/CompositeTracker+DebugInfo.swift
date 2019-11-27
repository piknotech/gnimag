//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import MacTestingTools

public extension CompositeTracker {
    /// Create information about regression functions from each segment.
    /// Attention: this is a possibly expensive operation.
    var allDebugFunctionInfos: [FunctionDebugInfo] {
        var result = [FunctionDebugInfo]()
        let all = finalizedSegments + [currentSegment!]

        /// Convenience function to add a ScatterStrokable for a given function to the result.
        func add(_ function: Function, with color: ScatterColor, dash: FunctionDebugInfo.DashType, from startTime: Time, to endTime: Time) {
            let range = SimpleRange(from: startTime, to: endTime, enforceRegularity: true)
            let strokable = scatterStrokable(for: function, drawingRange: range)
            result.append(FunctionDebugInfo(function: function, strokable: strokable, color: color, dash: dash))
        }

        // Add ScatterStrokables for each segment
        for (i, segment) in all.enumerated() {
            let endTime = (i < all.count - 1) ? all[i+1].supposedStartTime : timeInfinity
            let color = segment.colorForPlotting

            // Regression function
            if let function = segment.tracker.regression {
                add(function, with: color, dash: .solid, from: segment.supposedStartTime, to: endTime)
            }

            // Guesses
            else if let guesses = segment.guesses {
                for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                    add(function, with: color, dash: .dashed, from: startTime, to: endTime)
                }
            }
        }

        // Guesses for next segment
        if let guesses = mostRecentGuessesForNextSegment {
            let color = currentSegment.colorForPlotting == .even ? ScatterColor.odd : .even
            for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                add(function, with: color, dash: .dashed, from: startTime, to: timeInfinity)
            }
        }

        return result
    }
}
