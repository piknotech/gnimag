//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// BarPhysicsRecorder stores a BarPhysicsRecord for each bar movement character. When the bar movement character changes during the game, the correct BarPhysicsRecord is selected and can be used for bar prediction.
final class BarPhysicsRecorder {
    let playfield: Playfield

    /// The current bar movement character. This can change during the game.
    var barCharacter: BarMovementCharacter

    /// Default initializer.
    init(playfield: Playfield, barCharacter: BarMovementCharacter) {
        self.playfield = playfield
        self.barCharacter = barCharacter
    }

    private lazy var normalRecord = BarPhysicsRecord(playfield: playfield, holeSizeGuess: 35%, switchDistanceGuess: 29.5%)
    private lazy var hardFastRecord = BarPhysicsRecord(playfield: playfield, holeSizeGuess: 39%, switchDistanceGuess: 26%)
    private lazy var hardManyRecord = BarPhysicsRecord(playfield: playfield, holeSizeGuess: 42%, switchDistanceGuess: 25%)

    /// The current record, depending on the bar character.
    private var currentRecord: BarPhysicsRecord {
        switch barCharacter {
        case .normal: return normalRecord
        case .hardFast: return hardFastRecord
        case .hardMany: return hardManyRecord
        }
    }

    // MARK: Forwarded Methods from BarPhysicsRecord
    /// Return or guess the hole size for a bar.
    func holeSize(for bar: BarTracker) -> Double {
        currentRecord.holeSize(for: bar)
    }

    /// Return or guess the switch values for a bar.
    func switchValues(for bar: BarTracker) -> (lowerBound: Double, upperBound: Double) {
        currentRecord.switchValues(for: bar)
    }

    func update(with bar: BarTracker) {
        currentRecord.update(with: bar)
    }
}
