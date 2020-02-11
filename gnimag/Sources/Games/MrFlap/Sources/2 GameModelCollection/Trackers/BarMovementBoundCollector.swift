//
//  Created by David Knothe on 09.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

/// An instance of this class stores information about the hole movement bounds (yCenter) of a single bar type.
/// This allows to retrieve guesses for bar trackers where no lower or upper bound values are existing yet.
final class BarMovementBoundCollector {
    private let playfield: Playfield

    /// A guess of what percentage of the playfield free space the shared bound value may be.
    private let guessPercentageOfPlayfieldFreeSpace: Double

    /// The tracker for the shared bound value.
    /// Shared means that the value is the same for upper and lower bound, up to a reflection at the playfield midpoint (midcircle).
    private let sharedBoundValueTracker = ConstantTracker()

    /// Default initializer.
    init(playfield: Playfield, guessPercentage: Double) {
        self.playfield = playfield
        self.guessPercentageOfPlayfieldFreeSpace = guessPercentage
    }

    /// Provide guesses for a bar's lower and upper bound.
    /// If existing, values from the bar itself are used.
    /// If not, the shared bound value or the guess percentage are used as a fallback.
    func guesses(for bar: BarCourse) -> (lowerBound: Double, upperBound: Double) {
        // Case 1: Nothing to guess
        if let lower = bar.yCenter.lowerBound, let upper = bar.yCenter.upperBound {
            return (lower, upper)
        }

        // Case 2: Guess either upper or lower bound, based on reflection at the midpoint
        if let lower = bar.yCenter.lowerBound {
            return (lower, playfield.freeSpace - lower)
        }

        if let upper = bar.yCenter.upperBound {
            return (playfield.freeSpace - upper, upper)
        }

        // Case 3: Use shared bound value as guess
        if let shared = sharedBoundValueTracker.average {
            return (shared, playfield.freeSpace - shared)
        }

        // Case 4: Use guess percentage
        let guess = guessPercentageOfPlayfieldFreeSpace * playfield.freeSpace
        return (guess, playfield.freeSpace - guess)
    }

    /// Update the shared bound value with values from the bar tracker.
    func update(with bar: BarCourse) {
        if let lowerBound = bar.yCenter.lowerBound {
            sharedBoundValueTracker.add(value: lowerBound)
        }

        if let upperBound = bar.yCenter.upperBound {
            let value = playfield.freeSpace - upperBound
            sharedBoundValueTracker.add(value: value)
        }
    }
}
