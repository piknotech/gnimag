//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
final class GameModelCollector {
    let model = GameModel()

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    func accept(result: AnalysisResult, time: Double) {
        let (pairs, new) = match(dots: result.dots, to: model.dots, time: time)
        updateDotTrackers(with: pairs, new: new, time: time)

        for tracker in model.dots {
            print(tracker.yCenter.regression)
        }
    }

    /// Match dots from image analysis to their corresponding trackers.
    private func match(dots: [AnalysisResult.Dot], to trackers: [DotTracker], time: Double) -> (pairs: [DotTracker: AnalysisResult.Dot], new: [AnalysisResult.Dot]) {
        var pairs = [DotTracker: AnalysisResult.Dot]()
        var new = [AnalysisResult.Dot]()

        for dot in dots {
            let matching = trackers.filter {
                $0.yCenter.isDataPoint(value: dot.yCenter, time: time, validWithTolerance: .absolute(dot.radius), fallback: .useLastValue)
            }

            if matching.count == 0 {
                new.append(dot)
            } else if matching.count == 1 && pairs[matching[0]] == nil {
                pairs[matching[0]] = dot
            } else {
                print("Many matching!?")
            }
        }

        return (pairs, new)
    }

    /// Update the trackers with the result from `match`.
    private func updateDotTrackers(with pairs: [DotTracker: AnalysisResult.Dot], new: [AnalysisResult.Dot], time: Double) {
        // Update existing trackers
        for (tracker, dot) in pairs {
            if tracker.integrityCheck(with: dot, at: time) {
                tracker.update(with: dot, at: time)
            } else {
                print("Not integer!")
            }
        }

        // Create new trackers
        for newDot in new {
            let tracker = DotTracker(dot: newDot)
            tracker.update(with: newDot, at: time)
            model.dots.append(tracker)
        }
    }
}
