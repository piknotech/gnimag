//
//  Created by David Knothe on 15.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A PerformedTap describes a tap which was performed, in contrast to RelativeTap which describes a scheduled tap in the future.
/// PerformedTap is not relative to a reference point, but uses absolute time values.
public class PerformedTap {
    public let scheduledTap: ScheduledTap

    /// The absolute timepoint at which the tap was actually performed.
    public let performedAt: Double

    /// The absolute timepoint at which the tap was scheduled for.
    public var scheduledFor: Double {
        scheduledTap.absoluteTime
    }

    /// The absolute timepoint at which the tap was expected to be detected at.
    public var expectedDetectionTime: Double? {
        scheduledTap.expectedDetectionTime
    }

    /// The timepoint at which the tap was actually detected, if it was already detected.
    public var actualDetectionTime: Double?

    /// Default initializer.
    internal init(scheduledTap: ScheduledTap, performedAt: Double) {
        self.scheduledTap = scheduledTap
        self.performedAt = performedAt
    }
}

extension PerformedTap: CustomStringConvertible {
    public var description: String {
        "PerformedTap(scheduledTap: \(scheduledTap), performedAt: \(String(describing: performedAt)), actualDetectionTime: \(String(describing: actualDetectionTime)))"
    }
}
