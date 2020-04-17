//
//  Created by David Knothe on 17.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit
import LoggingKit

/// Data which is required to create a FullFramePlot.
struct FullFramePlotData {
    // MARK: Real-Time
    /// The absolute real (i.e. present) time of the received frame.
    let realFrameTime: Double

    /// The absolute real time after processing, but before performing tap prediction.
    /// A delay is added on top of this real time to obtain the future time of the tap prediction frame.
    let realTimeAfterProcessing: Double

    /// A snapshot of the player tracker.
    let playerHeight: CompositeTrackerDebugInfo<ParabolaTracker>

    /// The converter from player angle to time coordinates.
    let playerAngleConverter: PlayerAngleConverter

    /// All taps which have been performed in `[0, absoluteRealTime]`.
    let executedTaps: [PerformedTap]

    // MARK: Tap Prediction
    /// The tap prediction frame at the relevant timepoint.
    /// `frame.currentTime` is in the future (respective the delay) and does therefore not match `absoluteTime`.
    let frame: PredictionFrame

    /// The timeshift from real time to prediction time.
    var delay: Double {
        frame.currentTime - realTimeAfterProcessing
    }

    /// The solution of the current frame.
    /// Nil when there was no tap prediction because a previous solution is already locked.
    let solution: InteractionSolutionStrategy.Solution?
}
