//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

/// PlayerCourse bundles trackers for the player position which is defined by angle and height.

final class PlayerCourse {
    /// The angle and height trackers.
    let angle: Circular<LinearTracker>
    let height: JumpTracker

    /// The size of the player.
    let size: ConstantTracker

    /// Default initializer.
    init(playfield: Playfield) {
        angle = Circular(LinearTracker())
        height = JumpTracker(valueRangeTolerance: 10%, jumpTolerance: 2% * playfield.freeSpace)
        size = ConstantTracker()
    }

    // MARK: Updating

    /// Update the trackers with the values from the given player.
    /// When one of the values does not match into the tracked course, discard the values and return an error.
    func update(with player: Player, at time: Double) -> Result<Void, UpdateError> {
        if case let .failure(error) = integrityCheck(with: player, at: time) {
            return .failure(error)
        }

        // Add all values to trackers
        angle.add(value: player.angle, at: time)
        size.add(value: player.size)
        let linearAngle = angle.linearify(player.angle, at: time) // Map angle from [0, 2pi) to R
        height.add(value: player.height, at: linearAngle)

        return .success(())
    }

    /// Check if all given values match the trackers. If not, return an error.
    private func integrityCheck(with player: Player, at time: Double) -> Result<Void, UpdateError> {
        guard angle.is(player.angle, at: time, validWith: .absolute(tolerance: 2% * .pi)) else {
            return .failure(.wrongAngle)
        }

        guard size.is(player.size, validWith: .relative(tolerance: 10%)) else {
            return .failure(.wrongSize)
        }

        return .success(())
    }


    /// Errors that can occur when calling "update" with malformed values.
    enum UpdateError: Error {
        case wrongSize
        case wrongAngle
    }
}
