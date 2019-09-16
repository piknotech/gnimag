//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// ColorMatchSequence is a sequential collection of ColorMatches.
public struct ColorMatchSequence {
    public let sequence: [ColorMatch]

    /// Initialize the sequence with an array.
    /// The array must not be empty.
    public init(_ sequence: [ColorMatch]) {
        self.sequence = sequence
    }

    /// Initialize the sequence with variadic arguments.
    /// The arguments must not be empty.
    public init(_ sequence: ColorMatch...) {
        self.sequence = sequence
    }

    /// Initialize with a tolerance and a sequence of colors or anti-colors (!blue).
    public init(tolerance: Double, colors: [NeedsToleranceValue]) {
        self.sequence = colors.map { $0.withTolerance(tolerance) }
    }
}
