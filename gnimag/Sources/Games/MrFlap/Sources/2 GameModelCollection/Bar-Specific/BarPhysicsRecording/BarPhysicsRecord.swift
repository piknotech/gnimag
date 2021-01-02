//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// A BarPhysicsRecord records various properties of bars, in particular their hole size and their switch distance.
/// If these properties are required for a bar where it is not yet known, they can be taken from the BarPhysicsRecord.
/// Also, BarPhysicsRecord provides good guesses for these properties, for the beginning where there are no recorded values yet.
final class BarPhysicsRecord {
    private let holeSizeCollector: BarHoleSizeCollector
    private let switchBoundCollector: BarSwitchBoundCollector

    /// Default initializer.
    init(playfield: Playfield, holeSizeGuess: Double, switchDistanceGuess: Double) {
        holeSizeCollector = BarHoleSizeCollector(playfield: playfield, guess: holeSizeGuess)
        switchBoundCollector = BarSwitchBoundCollector(playfield: playfield, guess: switchDistanceGuess)
    }

    /// Return or guess the hole size for a bar.
    func holeSize(for bar: BarTracker) -> Double {
        holeSizeCollector.guess(for: bar)
    }

    /// Return or guess the switch values for a bar.
    func switchValues(for bar: BarTracker) -> (lowerBound: Double, upperBound: Double) {
        switchBoundCollector.guesses(for: bar)
    }
    
    func update(with bar: BarTracker) {
        holeSizeCollector.update(with: bar)
        switchBoundCollector.update(with: bar)
    }
}
