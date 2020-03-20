//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import TestingTools

public extension CompositeTracker {
    /// Return the dataSet from the most recent `numSegments` segments.
    /// This includes:
    /// - Valid points that have been added to the trackers,
    /// - Invalid points that failed the `integrityCheck`,
    /// - Points that are currently in the decision window and therefore probably belong to the next segment.
    func dataSet(forMostRecentSegments numSegments: Int) -> [ScatterDataPoint] {
        let firstSegment = allSegments.count - numSegments
        return allDataPoints.dataPoints(forSegmentIndicesInRange: firstSegment...) +
        window.dataPoints.map { ScatterDataPoint(x: $0.time, y: $0.value, color: .inDecisionWindow) }
    }

    /// Create information about the regression functions from the most recent `numSegments` segments.
    /// This includes guesses and creates a very clear picture.
    func allDebugFunctionInfos(numSegments: Int = .max) -> [FunctionDebugInfo] {
        var result = [FunctionDebugInfo]()
        let segments = Array(allSegments.suffix(numSegments))

        /// Convenience function to add a ScatterStrokable for a given function to the result.
        func add(_ function: SegmentTrackerType.F, with color: ScatterColor, dash: FunctionDebugInfo.DashType, from startTime: Time, to endTime: Time) {
            let range = SimpleRange(from: startTime, to: endTime, enforceRegularity: true)
            let strokable = scatterStrokable(for: function, drawingRange: range)
            result.append(FunctionDebugInfo(function: function, strokable: strokable, color: color, dash: dash))
        }

        // Add ScatterStrokables for each segment
        for (i, segment) in segments.enumerated() {
            let startTime = segment.supposedStartTime ?? -timeInfinity
            let endTime = ((i < segments.count - 1) ? segments[i+1].supposedStartTime : nil) ?? timeInfinity
            let color = segment.colorForPlotting

            // Regression function
            if let function = segment.tracker.regression {
                add(function, with: color, dash: .solid, from: startTime, to: endTime)
            }

            // Guesses
            else if let guesses = segment.guesses {
                for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                    add(function, with: color, dash: .dashed, from: startTime, to: endTime)
                }
            }
        }

        // Guesses for next segment
        let colorForGuesses: ScatterColor = {
            if case .even = currentSegment.colorForPlotting {
                return .odd
            } else {
                return .even
            }
        }()

        if let guesses = mostRecentGuessesForNextSegment {
            for (startTime, function) in zip(guesses.allStartTimes, guesses.all) {
                add(function, with: colorForGuesses, dash: .dashed, from: startTime, to: timeInfinity)
            }
        }

        return result
    }

    /// Information about the regressions and tolerance bound functions from the last `numSegments` segments.
    /// Does not include any guesses.
    func segmentwiseFullDebugFunctionInfos(numSegments: Int = .max) -> [FunctionDebugInfo] {
        return allSegments.suffix(numSegments).flatMap(\.tracker.allDebugFunctionInfos)
    }

    /// The most distant value for time.
    /// Because time direction can either be increasing or decreasing, this is either + or -infinity.
    private var timeInfinity: Time {
        monotonicityChecker.direction == .decreasing ? -.infinity : +.infinity
    }
}
