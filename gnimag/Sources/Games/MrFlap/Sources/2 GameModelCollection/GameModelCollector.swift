//
//  Created by David Knothe on 17.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

/// GameModelCollector accepts output from image analysis to create and update an up-to-date game model.
/// Before new results from image analysis are added, they are first checked for data integrity.
class GameModelCollector {
    let model: GameModel

    /// Default initializer.
    init(playfield: Playfield) {
        model = GameModel(playfield: playfield)
    }

    /// Use the AnalysisResult to update the game model.
    /// Before actually updating the game model, the integrity of the result is checked.
    func accept(result: AnalysisResult, time: Double) {
        // Update player
        if model.player.integrityCheck(with: result.player, at: time) {
            model.player.update(with: result.player, at: time)
        } else {
            print("player not integer (\(result.player))")
        }

        // Bars: instead of using the game time, use the player angle for bar-related trackers. This is useful to prevent small lags (which stop both the player and the bars) from destroying all of the tracking.
        let playerAngle = model.player.angle.linearify(result.player.angle, at: time) // Map angle from [0, 2pi) to R

        // Match model-bars to tracker-bars; update existing bars and add new bars
        let (pairs, newBars) = match(bars: result.bars, to: model.bars, time: playerAngle)
        print(newBars)
        
        for (tracker, bar) in pairs {
            if tracker.integrityCheck(with: bar, at: playerAngle) {
                tracker.update(with: bar, at: playerAngle)
            } else {
                print("bar not integer (\(bar))")
            }
        }

        for bar in newBars {
            let tracker = BarCourse(playfield: model.playfield)
            tracker.update(with: bar, at: playerAngle)
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
            tracker.angle.is(bar.angle, at: time, validWith: .absolute(tolerance: .pi / 8), fallbackWhenNoRegression: .useLastValue) // Works for up to 8 bars
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