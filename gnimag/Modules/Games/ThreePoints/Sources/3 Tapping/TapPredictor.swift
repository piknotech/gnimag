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
    private let delay: Double = 0.15

    /// Default initializer.
    init(playfield: Playfield, tapper: SomewhereTapper, timeProvider: TimeProvider) {
        self.playfield = playfield
        super.init(tapper: tapper, timeProvider: timeProvider, tapDelayTolerance: .absolute(0.2))
    }

    /// All active tap monitors, i.e. all taps which have been performed, but are not yet visible for image analysis.
    /// A monitor is removed either when the tap is seen to have been executed or when it is not detected until the monitor's trigger time. In this case, a fresh tap will be executed.
    var monitors = [TapMonitor]()

    /// Calculate, given the situation in the game model and the imageProvider's current time, how often the screen should be tapped IN THIS MOMENT sequentially to rotate to the current color.
    func howManyTaps(gameModel: GameModel) -> Int {
        0
    }
}

/// Each TapMonitor corresponds to a single tap and monitors whether it has actually been executed.
struct TapMonitor {
    let targetColor: DotColor

    /// If the tap hasn't been detected till this time, the tap monitor will regard this tap as not executed.
    let triggerTime: Double
}
