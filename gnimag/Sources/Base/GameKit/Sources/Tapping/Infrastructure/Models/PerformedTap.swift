//
//  Created by David Knothe on 15.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A PerformedTap describes a tap which was performed, in contrast to RelativeTap which describes a scheduled tap in the future.
/// PerformedTap is not relative to a reference point, but uses absolute time values.
public class PerformedTap {
    public let scheduledTap: ScheduledTap
    
    /// The absolute timepoint at which the tap was performed at.
    public var performedAt: Double {
        scheduledTap.absoluteTime
    }

    /// The absolute timepoint at which the tap was expected to be detected at.
    public var expectedDetectionTime: Double? {
        scheduledTap.expectedDetectionTime
    }

    /// The timepoint at which the tap was actually detected, if it was already detected.
    public var actualDetectionTime: Double?

    /// Default initializer.
    internal init(scheduledTap: ScheduledTap) {
        self.scheduledTap = scheduledTap
    }
}
