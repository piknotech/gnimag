//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// TapSequence defines a sequence of future taps that can be scheduled.
public final class TapSequence {
    /// All taps the sequence consists of.
    public var taps: [Tap]

    /// The absolute timepoint when this sequence is completed.
    /// At this time, the tap lock will be released.
    public let unlockTime: Double?

    /// The smallest time value in this sequence.
    public var nextTapTime: Double? {
        taps.map { $0.absoluteTime }.min()
    }

    /// Default intializer.
    public init(taps: [Tap], unlockTime: Double?) {
        self.taps = taps
        self.unlockTime = unlockTime
    }

    /// Default intializer, creating new taps for each tap time.
    public convenience init(tapTimes: [Double], unlockTime: Double?) {
        let taps = tapTimes.map(Tap.init)
        self.init(taps: taps, unlockTime: unlockTime)
    }

    /// Remove a tap from the sequence.
    /// Call this, for example, after the tap has been performed.
    public func remove(tap: Tap) {
        taps.removeAll { tap == $0 }
    }
}
