//
//  Created by David Knothe on 17.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit
import ObjectiveC

/// Debug information which can be attached to a tap and later be used for debugging.
/// This is useful because the physics values in earlier frames are different than physics values from later frames and are lost when they are not stored somewhere. Therefore, when previously predicted jumps want to be recovered, it is required to store the tap along with the specific physic values (i.e. the jump parabola).
struct TapDebugInfo {
    let referenceTime: Double

    /// The jump which is triggered by this tap.
    /// Thereby, the jump is relative to `referenceTime`, i.e. 0 corresponds to referenceTime.
    let jump: Jump
}

/// This extends RelativeTap (and the other taps) with debug information about the expected jump that this tap triggers.
extension RelativeTap {
    private static var associationKey = 0

    var debugInfo: TapDebugInfo? {
        get { objc_getAssociatedObject(self, &Self.associationKey) as? TapDebugInfo }
        set { objc_setAssociatedObject(self, &Self.associationKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

extension ScheduledTap {
    var debugInfo: TapDebugInfo? {
        get { relativeTap.debugInfo }
        set { relativeTap.debugInfo = newValue }
    }
}

extension PerformedTap {
    var debugInfo: TapDebugInfo? {
        get { scheduledTap.debugInfo }
        set { scheduledTap.debugInfo = newValue }
    }
}

extension RelativeTap: Withable { }
