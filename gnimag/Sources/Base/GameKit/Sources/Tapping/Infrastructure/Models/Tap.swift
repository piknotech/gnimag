//
//  Created by David Knothe on 27.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// A Tap describes a scheduled tap.
public struct Tap: Equatable {
    /// The absolute point in time at which the tap should be performed.
    public let absoluteTime: Double

    /// Default initializer.
    public init(absoluteTime: Double) {
        self.absoluteTime = absoluteTime
    }

    /// Compare two Taps. Two Taps are equal if they have the exact same absoluteTime.
    public static func ==(lhs: Tap, rhs: Tap) -> Bool {
        lhs.absoluteTime == rhs.absoluteTime
    }
}
