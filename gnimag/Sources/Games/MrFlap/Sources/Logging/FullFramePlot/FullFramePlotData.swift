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

    /// A snapshot of the player tracker.
    let playerHeight: CompositeTrackerDebugInfo<ParabolaTracker>

    /// The converter from player angle to time coordinates.
    let playerAngleConverter: PlayerAngleConverter

    // MARK: Tap Prediction And Scheduling
    /// The taps that are currently scheduled.
    /// These were either calculated in this frame or, when a lock is active, in a previous one.
    let scheduledTaps: [ScheduledTap]

    /// All taps which have been performed in `[0, absoluteRealTime]`.
    let executedTaps: [PerformedTap]

    /// The tap prediction frame at the relevant timepoint.
    /// `frame.currentTime` is in the future (respective the delay) and does therefore not match `absoluteTime`.
    let frame: PredictionFrame

    /// The recorder storing all interactions that happened in the past.
    let interactionRecorder: InteractionRecorder
}
