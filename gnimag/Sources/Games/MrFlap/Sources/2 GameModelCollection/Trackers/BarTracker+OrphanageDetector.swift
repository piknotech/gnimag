//
//  Created by David Knothe on 13.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// BarTrackerOrphanageDetector detects whether a BarTracker is either not used anymore or triggering too many integrity errors.
/// This can happen in two cases: either the bar has disappeared, or it was detected and created erroneously.
final class BarTrackerOrphanageDetector {
    /// The number of frames the tracker has not been updated for.
    /// After 5 frames, the bar is marked as orphaned.
    private var consecutiveNumberOfFramesWithoutUpdate = 0

    var isOrphaned: Bool {
        consecutiveNumberOfFramesWithoutUpdate >= 5
    }

    /// Call at the beginning of each frame. This increases the `consecutiveNumberOfFramesWithoutUpdate` counter.
    func newFrame() {
        consecutiveNumberOfFramesWithoutUpdate += 1
    }

    /// Call when the bar has been validly updated. This resets the `consecutiveNumberOfFramesWithoutUpdate` counter.
    func markBarAsValid() {
        consecutiveNumberOfFramesWithoutUpdate = 0
    }
}