//
//  Created by David Knothe on 15.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
/// Attention: a value-copy of a RelativeTapSequence contains a new array of taps, but the taps refer to the same RelativeTap instances (as RelativeTap is a class).
public struct RelativeTapSequence {
    /// All taps the sequence consists of.
    /// These are sorted by their respective `relativeTime`s.
    public private(set) var taps: [RelativeTap]

    /// The duration, from the start of the sequence, until this sequence is completed.
    /// At this time, the tap lock will be released.
    public let unlockDuration: Double?

    /// The smallest time value in this sequence.
    public var nextTap: RelativeTap? {
        taps.first
    }

    /// Default intializer.
    public init(taps: [RelativeTap], unlockDuration: Double?, isAlreadySorted: Bool = false) {
        if isAlreadySorted {
            self.taps = taps
        } else {
            self.taps = taps.sorted { $0.relativeTime < $1.relativeTime }
        }

        self.unlockDuration = unlockDuration
    }

    /// Remove a tap from the sequence in-place.
    mutating func remove(tap: RelativeTap) {
        taps.removeAll { tap === $0 }
    }
}


extension RelativeTapSequence: CustomStringConvertible {
    public var description: String {
        let sortedTaps = taps.sorted { $0.relativeTime < $1.relativeTime }
        return "RelativeTapSequence(taps: \(sortedTaps), unlockDuration: \(String(describing: unlockDuration)))"
    }
}
