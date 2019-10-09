//
//  Created by David Knothe on 07.10.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

public final class CompositeCore {
    /// Chracteristics which describe how and when to make a segment advancement decision.
    struct NextSegmentDecisionCharacteristics {
        /// The number of points which must match the next segment.
        /// When this is 1, `maxIntermediatePointsMatchingCurrentSegment` is irrelevant, as there are no intermediate points.
        let pointsMatchingNextSegment: Int

        /// During the interval in which `pointsMatchingNextSegment` points matching the next segment are collected, at most `maxIntermediatePointsMatchingCurrentSegment` are allowed to match the current, old segment.
        /// If more points match the current segment, the decision action is cancelled.
        let maxIntermediatePointsMatchingCurrentSegment: Int
    }

    enum State {
        case decidingToAdvance
        case missingDataPointsForCurrentTracker
        case normal
    }
}
