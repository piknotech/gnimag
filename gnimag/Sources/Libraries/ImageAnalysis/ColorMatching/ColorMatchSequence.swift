//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// ColorMatchSequence is a sequential collection of ColorMatches.
public struct ColorMatchSequence {
    public let sequence: [ColorMatch]

    /// Initialize the sequence with an array.
    public init(_ sequence: [ColorMatch]) {
        self.sequence = sequence
    }

    /// Initialize the sequence with variadic arguments.
    public init(_ sequence: ColorMatch...) {
        self.sequence = sequence
    }
}
