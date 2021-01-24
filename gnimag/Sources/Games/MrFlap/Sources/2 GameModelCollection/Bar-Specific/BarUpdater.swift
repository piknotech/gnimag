//
//  Created by David Knothe on 13.02.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// BarUpdater performs the task of matching and updating the game model with new bars from ImageAnalysis.
struct BarUpdater {
    let gmc: GameModelCollector
    let model: GameModel
    let recorder: BarMovementRecorder

    init(gmc: GameModelCollector) {
        self.gmc = gmc
        model = gmc.model
        recorder = gmc.barPhysicsRecorder
    }

    /// Match the bars to the bar trackers and update each tracker.
    func matchAndUpdate(bars: [Bar], time: Double, debugLogger: DebugLogger) {
        let matches = match(bars: bars, time: time)
        updateTrackers(with: matches.pairs, newBars: matches.newBars, time: time, debugLogger: debugLogger)
    }

    /// Match the bars to the bar trackers, solely based on their respective angles.
    /// Return the matched pairs and the bars that did not match to any tracker (and thus are new).
    private func match(bars: [Bar], time: Double) -> (pairs: [BarTracker: Bar], newBars: [Bar]) {
        var pairs = [BarTracker: Bar]()
        var newBars = [Bar]()

        // Find matching tracker for each bar
        for bar in bars {
            // Find all trackers that match the given bar, angle-wise
            let matches = model.bars.filter {
                $0.angle.isDataPointValid(value: bar.angle, time: time, fallback: .useLastValue)
            }

            switch matches.count {
            case 0:
                newBars.append(bar)

            case 1:
                let match = matches.first!
                pairs[match] = bar

            default: // More than 1 matching tracker – give bar to the one with the most values
                let match = matches.max {
                    $0.angle.values.count < $1.angle.values.count
                }!
                pairs[match] = bar
            }
        }

        return (pairs, newBars)
    }

    /// Update the bar trackers with the matching result.
    private func updateTrackers(with pairs: [BarTracker: Bar], newBars: [Bar], time: Double, debugLogger: DebugLogger) {
        let character = FineBarMovementCharacter(gameMode: gmc.mode, points: gmc.points.points)

        // Update all trackers
        for tracker in model.bars {
            tracker.orphanage.newFrame()
            tracker.setupDebugLogging()

            // If tracker is associated with a bar from image analysis, update the tracker
            if let bar = pairs[tracker] {
                if tracker.integrityCheck(with: bar, at: time, gameMovementCharacter: character) {
                    tracker.update(with: bar, at: time)
                    recorder.update(with: tracker)
                } else {
                    tracker.integrityCheckUnsuccessful()
                }
            }

            tracker.performDebugLogging()
        }

        // Create trackers from new bars
        for bar in newBars {
            let tracker = BarTracker(playfield: model.playfield, movement: gmc.fineCharacter, debugLogger: debugLogger)
            tracker.setupDebugLogging()
            tracker.update(with: bar, at: time)
            recorder.update(with: tracker)
            tracker.performDebugLogging()
            model.bars.append(tracker)
        }

        // Remove orphaned trackers and trigger orphaned events
        model.bars.removeAll { tracker in
            if tracker.orphanage.isOrphaned {
                tracker.disappearingOrOrphaned.trigger()
                return true
            } else {
                return false
            }
        }
    }
}
