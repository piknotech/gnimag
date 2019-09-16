//
//  Created by David Knothe on 27.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// ColorMatch describes a function that maps color values onto {true, false}.
public indirect enum ColorMatch {
    case block((Color) -> Bool)
    case color(Color, tolerance: Double)
    case not(ColorMatch)

    /// Return true iff the given color matches the rule.
    func matches(_ color: Color) -> Bool {
        switch self {
        case let .block(block):
            return block(color)

        case let .color(allowed, tolerance):
            return color.distance(to: allowed) <= tolerance

        case let .not(other):
            return !other.matches(color)
        }
    }
}

/// Negate a ColorMatch.
public prefix func !(match: ColorMatch) -> ColorMatch {
    return .not(match)
}

// MARK: Syntactic Sugar for ColorMatchSequence
public protocol NeedsToleranceValue {
    /// Transform the value into a ColorMatch using the given tolerance.
    func withTolerance(_ tolerance: Double) -> ColorMatch
}

fileprivate struct NegatedColor: NeedsToleranceValue {
    let originalColor: Color

    func withTolerance(_ tolerance: Double) -> ColorMatch {
        return .not(originalColor.withTolerance(tolerance))
    }
}

/// Negate a color. Use "withTolerance" to turn the negated color into a ColorMatch.
public prefix func !(color: Color) -> NeedsToleranceValue {
    return NegatedColor(originalColor: color)
}

extension Color: NeedsToleranceValue {
    /// Return a color match that matches each color that is inside a given threshold.
    public func withTolerance(_ tolerance: Double) -> ColorMatch {
        .color(self, tolerance: tolerance)
    }
}
