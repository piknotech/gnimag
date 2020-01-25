//
//  Created by David Knothe on 25.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

/// A Tap is an object uniquely identifying a scheduled tap.
/// Multiple Tap instances can refer to the same scheduled tap, but from a different time perspective. Therefore, taps can be compared using their identifier.
public struct Tap: Equatable {
    /// The duration, relative to now, until the tap should be performed.
    public let time: Double
    private let id: UUID

    /// Default initializer.
    public init(time: Double) {
        self.id = UUID()
        self.time = time
    }

    /// Create a Tap from an existing tap, but from a different time perspective (subtracting a time interval).
    /// Both Tap instaces refer to the same tap (i.e. have the same ID and will compare equal using ==).
    public init(subtracting difference: Double, from tap: Tap) {
        self.id = tap.id
        self.time = tap.time - difference
    }

    /// Check if two Tap instances refer to the same tap, but possibly from a different time perspective.
    public static func ==(lhs: Tap, rhs: Tap) -> Bool {
        lhs.id == rhs.id
    }
}

/// TapSequence defines a sequence of future taps that can be scheduled.
public struct TapSequence {
    /// All taps that will be scheduled.
    public let taps: [Tap]

    /// The time until the sequence is completed.
    /// At this time, the tap lock will be released.
    public let unlockTime: Double?

    /// The duration until the first tap of the sequence will be performed.
    public var nextTapTime: Double? {
        taps.map { $0.time }.min()
    }

    /// Default intializer, creating new taps for each tap time.
    public init(tapTimes: [Double], unlockTime: Double?) {
        let taps = tapTimes.map(Tap.init)
        self.init(taps: taps, unlockTime: unlockTime)
    }

    /// Default intializer.
    public init(taps: [Tap], unlockTime: Double?) {
        self.taps = taps
        self.unlockTime = unlockTime
    }

    /// The tap sequence which arises after a given tap in this sequence has been executed.
    /// All taps are time-shifted relative to the current time (so that the executed tap time corresponds to 0), but will still refer to the same tap (ID-wise).
    public func afterExecuting(tap: Tap) -> TapSequence {
        var result = taps

        // Find corresponding tap
        guard let i = (taps.firstIndex { $0 == tap }) else { return self }
        let tap = result.remove(at: i)

        result = result.map { Tap(subtracting: tap.time, from: $0) }
        let unlockTime = self.unlockTime.map { $0 - tap.time }

        return TapSequence(taps: result, unlockTime: unlockTime)
    }
}
