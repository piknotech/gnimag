//
//  Created by David Knothe on 15.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common

/// A RelativeTap describes a scheduled tap relative to a non-specified reference point in time.
public class RelativeTap {
    /// The duration until when the tap will be performed.
    /// Is always non-negative.
    public let relativeTime: Double

    /// Default initializer.
    /// If `relativeTime` is negative, it will be set to zero.
    public init(scheduledIn relativeTime: Double) {
        if relativeTime < 0 {
            Terminal.log(.warning, "RelativeTap – tap has negative relativeTime \(relativeTime).")
        }

        self.relativeTime = max(0, relativeTime)
    }
}

extension RelativeTap: CustomStringConvertible {
    public var description: String {
        "RelativeTap(in: \(relativeTime))"
    }
}

// MARK: Sequence

/// RelativeTapSequence defines a sequence of scheduled taps relative to a non-specified reference point in time.
public class RelativeTapSequence {
    /// All taps the sequence consists of.
    public private(set) var taps: [RelativeTap]

    /// The duration, from the start of the sequence, until this sequence is completed.
    /// At this time, the tap lock will be released.
    public let unlockDuration: Double?

    /// The smallest time value in this sequence.
    public var nextTap: RelativeTap? {
        taps.min(by: \.relativeTime)
    }

    /// Default intializer.
    public init(taps: [RelativeTap], unlockDuration: Double?) {
        self.taps = taps
        self.unlockDuration = unlockDuration
    }

    /// Remove a tap from the sequence.
    func remove(tap: RelativeTap) {
        taps.removeAll { tap === $0 }
    }
}


extension RelativeTapSequence: CustomStringConvertible {
    public var description: String {
        let sortedTaps = taps.sorted { $0.relativeTime < $1.relativeTime }
        return "RelativeTapSequence(taps: \(sortedTaps), unlockDuration: \(String(describing: unlockDuration)))"
    }
}
