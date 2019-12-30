//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
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
    init(playfield: Playfield, debugLogger: DebugLogger) {
        model = GameModel(playfield: playfield, debugLogger: debugLogger)
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

    /// Update the bar trackers with the result from the matching algorithm.
    private func updateBars(with pairs: [BarCourse: Bar], newBars: [Bar], playerAngle: Double) {
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

        // Add new bars
        for bar in newBars {
            let tracker = BarCourse(playfield: model.playfield, debugLogger: debugLogger)
            tracker.setupDebugLogging()
            tracker.update(with: bar, at: playerAngle)
            tracker.performDebugLogging()
            model.bars.append(tracker)
        }
    }

    /// Match the bars to the bar trackers, solely based on their respective angles.
    /// Return the matched pairs and the bars that did not match to any tracker (and thus are new).
    private func match(bars: [Bar], to trackers: [BarCourse], time: Double) -> (pairs: [BarCourse: Bar], newBars: [Bar]) {
        var pairs = [BarCourse: Bar]()
        var newBars = [Bar]()

        // Check if the given tracker matches the given bar, angle-wise.
        func tracker(_ tracker: BarCourse, matches bar: Bar) -> Bool {
            pairs[tracker] == nil && // Tracker cannot be already taken by another bar
            tracker.angle.isDataPoint(value: bar.angle, time: time, validWithTolerance: .absolute(.pi / 8), fallback: .useLastValue) // Works for up to 8 bars
        }

        // Find matching tracker for each bar
        for bar in bars {
            if let match = (trackers.first { tracker($0, matches: bar) }) {
                pairs[match] = bar
            } else {
                newBars.append(bar)
            }
        }

        return (pairs, newBars)
    }
}
