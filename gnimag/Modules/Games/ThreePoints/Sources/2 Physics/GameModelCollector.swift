//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
final class GameModelCollector {
    let model = GameModel()

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    func accept(result: AnalysisResult, time: Double) {
        // Match dots to trackers and update
        let (pairs, new) = match(dots: result.dots, to: model.dots, time: time)
        updateDotTrackers(with: pairs, new: new, time: time)

        // Remove orphaned trackers
        model.dots.removeAll(where: \.orphanage.isOrphaned)

        // Update prism state tracker
        model.prism.update(with: result.prismRotation)
    }

    /// Match dots from image analysis to their corresponding trackers.
    private func match(dots: [Dot], to trackers: [DotTracker], time: Double) -> (pairs: [DotTracker: Dot], new: [Dot]) {
        var pairs = [DotTracker: Dot]()
        var new = [Dot]()

        for dot in dots {
            let matching = trackers.filter {
                dot.color == $0.color && $0.yCenter.isDataPoint(value: dot.yCenter, time: time, validWithTolerance: .absolute(dot.radius), fallback: .useLastValue)
            }

            if matching.count == 0 {
                new.append(dot)
            } else if matching.count == 1 && pairs[matching[0]] == nil {
                pairs[matching[0]] = dot
            } else {
                Terminal.log(.warning, "Multiple DotTrackers match the dot \(dot)")
            }
        }

        return (pairs, new)
    }

    /// Update the trackers with the result from `match`.
    private func updateDotTrackers(with pairs: [DotTracker: Dot], new: [Dot], time: Double) {
        for tracker in model.dots {
            tracker.orphanage.newFrame()
        }

        // Update existing trackers
        for (tracker, dot) in pairs {
            if tracker.integrityCheck(with: dot, at: time) {
                tracker.update(with: dot, at: time)
            } else {
                Terminal.log(.warning, "DotTracker - integrity error")
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
