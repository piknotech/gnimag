//
//  Created by David Knothe on 11.12.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// BarMovementRecorder stores a BarMovementRecord for each bar movement character. When the bar movement character changes during the game, the correct BarMovementRecord is selected and can be used for bar prediction.
final class BarMovementRecorder {
    let playfield: Playfield

    /// The current bar movement character. This can change during the game.
    var barCharacter: BarMovementCharacter

    /// Default initializer.
    init(playfield: Playfield, barCharacter: BarMovementCharacter) {
        self.playfield = playfield
        self.barCharacter = barCharacter
    }

    private lazy var normalBeginRecord = BarMovementRecord(playfield: playfield, holeSizeGuess: 35.5%, switchDistanceGuess: 29.5%)
    private lazy var normalEndRecord = BarMovementRecord(playfield: playfield, holeSizeGuess: 39%, switchDistanceGuess: 30.5%)
    private lazy var hardFastRecord = BarMovementRecord(playfield: playfield, holeSizeGuess: 40%, switchDistanceGuess: 27%)
    private lazy var hardManyRecord = BarMovementRecord(playfield: playfield, holeSizeGuess: 44%, switchDistanceGuess: 26.5%)

    /// The current record, depending on the bar character.
    private var currentRecord: BarMovementRecord {
        switch barCharacter {
        case .normalBegin: return normalBeginRecord
        case .normalEnd: return normalEndRecord
        case .hardFast: return hardFastRecord
        case .hardMany: return hardManyRecord
        }
    }

    // MARK: Forwarded Methods from BarMovementRecord
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
