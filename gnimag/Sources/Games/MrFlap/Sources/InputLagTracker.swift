//
//  Created by David Knothe on 04.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// InputLagTracker outputs warning messages when the input source lags, i.e. provides the same frame multiple times in a row.
/// This is independent of the time of the frames - InputLagTracker only considers whether multiple consecutive frames are similar.
internal class InputLagTracker {
    /// After 'warningThreshold' consecutive irrelevant frames, a warning will be produced. Must be at least 1.
    private let warningThreshold: Int

    /// Default initializer.
    init(warningThreshold: Int) {
        self.warningThreshold = warningThreshold
    }

    /// A human-readable, detailed description of the lagging statistics.
    var detailedInformation: String {
        let irrelevantFrames = String(format: "%.2f%%", irrelevantFrameRatio)
        let averageLag = String(format: "%.1f", averageLaggingDuration)

        return """
        InputLag information:
        • Irrelevant frames: \(irrelevantFrames)
        • Longest lag: \(longestLag) frames
        • Average lag: \(averageLag) frames
        """
    }

    /// The ratio of frames which were irrelevant, i.e. repeated.
    var irrelevantFrameRatio: Double {
        totalFrames == 0 ? 0 : Double(totalIrrelevantFrames) / Double(totalFrames)
    }

    /// The average duration of a lag, in frames.
    var averageLaggingDuration: Double {
        totalLags == 0 ? 0 : Double(totalIrrelevantFrames) / Double(totalLags)
    }

    /// The longest lag, in frames.
    private(set) var longestLag = 0

    private var consecutiveIrrelevantFrames = 0
    private var totalFrames = 0
    private var totalIrrelevantFrames = 0
    private var totalLags = 0

    enum FrameType {
        case new
        case irrelevant
    }

    /// Call this method after every frame. If the frame was new, call with '.new', else use '.irrelevant'.
    func registerFrame(being type: FrameType) {
        totalFrames += 1

        switch type {
        case .new:
            consecutiveIrrelevantFrames = 0

        case .irrelevant:
            totalIrrelevantFrames += 1
            consecutiveIrrelevantFrames += 1
        }

        longestLag = max(longestLag, consecutiveIrrelevantFrames)
        if consecutiveIrrelevantFrames == 1 {
            totalLags += 1
        }

        // Log if required
        if consecutiveIrrelevantFrames > 0 && consecutiveIrrelevantFrames.isMultiple(of: warningThreshold) {
            Terminal.log(.warning, "Lag (duration: \(consecutiveIrrelevantFrames) frames)")
        }
    }
}
