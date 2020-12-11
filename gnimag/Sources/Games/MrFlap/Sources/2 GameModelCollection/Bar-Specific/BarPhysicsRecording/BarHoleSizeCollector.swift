//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

/// An instance of this class stores information about the hole size of a single bar character type.
/// This allows to retrieve guesses for bar trackers where no hole size value is existing yet.
final class BarHoleSizeCollector {
    private let playfield: Playfield

    /// A guess of what percentage of the playfield free space the shared hole size value may be.
    private let guess: Double

    /// The tracker for the shared hole size value.
    private let holeSizeTracker = ConstantTracker(tolerance: .relative(20%))

    /// Default initializer.
    init(playfield: Playfield, guess: Double) {
        self.playfield = playfield
        self.guess = guess
    }

    /// Provide guesses for a bar's hole size.
    /// If existing, values from the bar itself are used.
    /// If not, the shared value or the guess percentage is used as a fallback.
    func guess(for bar: BarTracker) -> Double {
        // Case 1: Nothing to guess
        if let holeSize = bar.holeSize.average { return holeSize }

        // Case 2: Use shared bound value as guess
        if let shared = holeSizeTracker.average { return shared }

        // Case 3: Use guess percentage
        return guess * playfield.freeSpace
    }

    /// Update the shared tracker with the bar's hole size.
    func update(with bar: BarTracker) {
        if let holeSize = bar.holeSize.average, holeSizeTracker.isValueValid(holeSize) {
            holeSizeTracker.add(value: holeSize)
        }
    }
}
