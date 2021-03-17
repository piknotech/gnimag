//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit
import Image
import Tapping

/// TapPredictor is the main class dealing with tap prediction and scheduling.
final class TapPredictor: TapPredictorBase {
    private let playfield: Playfield
    private let gameModel: GameModel
    private let delay: Double = 0.05 // remove

    /// All active tap monitors, i.e. all taps which have been performed, but are not yet visible for image analysis.
    /// A monitor is removed either when the tap is seen to have been executed or when it is not detected until the monitor's trigger time. In this case, a fresh tap will be executed.
    var monitors = [TapMonitor]()

    /// Default initializer.
    init(playfield: Playfield, tapper: SomewhereTapper, timeProvider: TimeProvider, gameModel: GameModel) {
        self.playfield = playfield
        self.gameModel = gameModel

        super.init(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: .absolute(0.2))

        scheduler.tapPerformed.subscribe(tapPerformed(tap:))
    }

    /// Analyze the game model to schedule taps.
    /// Instead of using the current time, input+output delay is added.
    override func predictionLogic() -> AbsoluteTapSequence? {
        updateMonitors(realTime: timeProvider.currentTime)
        let taps = howManyTaps()

        if taps > 0 {
            print("TAP \(taps) TIMES!")
            // 100 ms between consecutive taps
            let taps = Array(0 ..< taps).map { RelativeTap(scheduledIn: 0 * Double($0)) }
            let relative = RelativeTapSequence(taps: taps, unlockDuration: nil)
            return AbsoluteTapSequence(relative, relativeTo: timeProvider.currentTime)
        }

        return nil
    }

    /// Update monitors: remove monitors which have been fulfilled or not fulfilled.
    /// Removing a monitor whose tap has not been detected by the smartphone will trigger a new tap to be generated by predictionLogic.
    private func updateMonitors(realTime: Double) {
        if let color = gameModel.prism.color.change {
            print("CHANGE TO:", color)
        }
        if let color = gameModel.prism.color.change, !monitors.isEmpty {
            let index = monitors.firstIndex { $0.color == color } ?? 0 // Remove 1 or 2 monitors
            monitors.removeFirst(index + 1)
            print("remove first \(index + 1) monitors. remaining: \(monitors.count)")
        }

        let c = monitors.count
        monitors.removeAll {
            realTime > $0.triggerTime
        }
        if c > monitors.count {
            print("NOT FULFILLED: \(c - monitors.count) MONITORS")
        }
    }

    /// Calculate, given the situation in the game model and the imageProvider's current time, how often the screen should be tapped *right now* (considering in+out delay) in order to rotate to the correct color.
    func howManyTaps() -> Int {
        let realTime = timeProvider.currentTime
        let delay = self.delay
        let currentTime = realTime + delay

        // Convert DotTrackers into DotProperties
        let dots = gameModel.dots
            .compactMap { DotProperties(playfield: playfield, tracker: $0, currentTime: currentTime) }
            .filter { $0.collisionWithPrism > 0 }
            .sorted(by: \.collisionWithPrism)

        guard let firstDot = dots.first, let prism = prismColor else { return 0 }
        print(firstDot.color, prism, prism.distance(to: firstDot.color))
        
        return prism.distance(to: firstDot.color)
    }

    /// The color the prism should have after all already-executed taps have been detected.
    private var prismColor: DotColor? {
        guard var color = gameModel.prism.color.value else { return nil }

        // Add not-yet-detected taps, i.e. all monitors
        for _ in monitors {
            color = color.next
        }

        return color
    }

    /// Called after a tap was performed by the scheduler.
    private func tapPerformed(tap: PerformedTap) {
        let monitor = TapMonitor(tap: tap, color: prismColor!.next, triggerTime: tap.performedAt + delay + 0.3)
        monitors.append(monitor)
    }
}

/// Each TapMonitor corresponds to a single tap and monitors whether it has actually been executed.
struct TapMonitor {
    let tap: PerformedTap

    /// The color which will be on top after this tap.
    let color: DotColor

    /// If the tap hasn't been detected until this time, the tap monitor will regard this tap as not executed.
    let triggerTime: Double
}
