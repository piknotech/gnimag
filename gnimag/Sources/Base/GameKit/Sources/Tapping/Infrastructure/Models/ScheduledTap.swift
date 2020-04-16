//
//  Created by David Knothe on 15.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// A ScheduledTap describes a tap which is scheduled, but not performed yet.
/// It correlates a RelativeTap to a specific reference time.
public class ScheduledTap {
    public let relativeTap: RelativeTap
    public let referenceTime: Double

    public var absoluteTime: Double {
        referenceTime + relativeTap.relativeTime
    }

    /// The absolute timepoint at which the tap is gonna be expected to be detected at.
    public let expectedDetectionTime: Double?

    /// Default initializer.
    internal init(relativeTap: RelativeTap, referenceTime: Double, expectedDetectionTime: Double?) {
        self.relativeTap = relativeTap
        self.referenceTime = referenceTime
        self.expectedDetectionTime = expectedDetectionTime
    }
}
