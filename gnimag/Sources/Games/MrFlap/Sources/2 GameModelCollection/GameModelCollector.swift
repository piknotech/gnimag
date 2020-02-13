//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
class GameModelCollector {
    let model: GameModel

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugLoggerFrame.GameModelCollection { debugLogger.currentFrame.gameModelCollection }

    /// Default initializer.
    init(playfield: Playfield, initialPlayer: Player, mode: GameMode, debugLogger: DebugLogger) {
        model = GameModel(playfield: playfield, initialPlayer: initialPlayer, mode: mode, debugLogger: debugLogger)
        self.debugLogger = debugLogger
    }

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    func accept(result: AnalysisResult, time: Double) {
        debugLogger.currentFrame.gameModelCollection.wasPerformed = true
        defer { model.player.performDebugLogging() }

        // Update player
        if model.player.integrityCheck(with: result.player, at: time) {
            model.player.update(with: result.player, at: time)
        } else {
            // When the player is not integer, bar tracking cannot proceed correctly
            // TODO: what happens when bar never leaves the appearing state? – detect this!
            print("player not integer (\(result.player))")
            return
        }

        // Bars: instead of using the game time, use the player angle for bar-related trackers. This is useful to prevent small lags (which stop both the player and the bars) from destroying all of the tracking.
        let playerAngle = model.player.angle.linearify(result.player.angle, at: time) // Map angle from [0, 2pi) to R

        // Match model-bars to tracker-bars
        let (pairs, newBars) = match(bars: result.bars, to: model.bars, time: playerAngle)
        updateBars(with: pairs, newBars: newBars, playerAngle: playerAngle)
    }

    // MARK: Bar Matching & Update

    /// Update the bar trackers with the result from the matching algorithm.
    private func updateBars(with pairs: [BarTracker: Bar], newBars: [Bar], playerAngle: Double) {
        // Update existing bars
        for (tracker, bar) in pairs {
            tracker.setupDebugLogging()

            if tracker.integrityCheck(with: bar, at: playerAngle) {
                tracker.update(with: bar, at: playerAngle)
            } else {
                print("bar not integer (\(bar))")
            }

            tracker.performDebugLogging()
        }

        // Record trackers that have not been matched
        let remainingTrackers = model.bars.filter { !pairs.keys.contains($0) }
        for tracker in remainingTrackers {
            tracker.consecutiveNumberOfFramesWithoutUpdate += 1
        }

        // Create trackers from new bars
        for bar in newBars {
            let tracker = BarTracker(playfield: model.playfield, debugLogger: debugLogger)
            tracker.setupDebugLogging()
            tracker.update(with: bar, at: playerAngle)
            tracker.performDebugLogging()
            model.bars.append(tracker)
        }

        // Remove orphaned trackers
        model.bars.removeAll { tracker in
            tracker.consecutiveNumberOfFramesWithoutUpdate >= 10
        }
    }

    /// Match the bars to the bar trackers, solely based on their respective angles.
    /// Return the matched pairs and the bars that did not match to any tracker (and thus are new).
    private func match(bars: [Bar], to trackers: [BarTracker], time: Double) -> (pairs: [BarTracker: Bar], newBars: [Bar]) {
        var pairs = [BarTracker: Bar]()
        var newBars = [Bar]()

        // Find matching tracker for each bar
        for bar in bars {
            // Find all trackers that match the given bar, angle-wise
            let matches = trackers.filter {
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
}
