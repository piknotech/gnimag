//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Input

/// ColorMatch describes a function that maps color values onto {true, false}.

public indirect enum ColorMatch {
    case block((Color) -> Bool)
    case color(Color, threshold: Double)
    case not(ColorMatch)

    /// Return true iff the given color matches the rule.
    func matches(_ color: Color) -> Bool {
        switch self {
        case let .block(block):
            return block(color)

        case let .color(allowed, threshold):
            return color.euclideanDifference(to: allowed) <= threshold

        case let .not(other):
            return !other.matches(color)
        }
    }
}

// MARK: Color extension
extension Color {
    /// Return a color match that matches each color that is inside a given threshold.
    public func threshold(_ threshold: Double) -> ColorMatch {
        .color(self, threshold: threshold)
    }
}
