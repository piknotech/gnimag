//
//  Created by David Knothe on 22.07.19.
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
        angle = Circular(LinearTracker(maxDataPoints: 500))
        height = JumpTracker(maxDataPoints: 500, valueRangeTolerance: 10%, jumpTolerance: 2% * playfield.fullRadius)
        size = ConstantTracker(maxDataPoints: 50)
    }

    // MARK: Updating

    /// Update the trackers with the values from the given player.
    /// When one of the values does not match into the tracked course, discard the values and return an error.
    func update(with player: Player, at time: Double) -> Result<Void, UpdateError> {
        guard !angle.hasRegression || angle.value(player.angle, isValidWithTolerance: 2% * .pi, at: time) else {
            return .failure(.wrongAngle)
        }

        guard !size.hasRegression || size.value(player.angle, isValidWithTolerance: 10% * size.average!) else {
            return .failure(.wrongSize)
        }

        angle.add(value: player.angle, at: time)
        height.add(value: player.height, at: time)
        size.add(value: player.size)

        return .success(())
    }

    /// Errors that can occur when calling "update" with malformed values.
    enum UpdateError: Error {
        case wrongSize
        case wrongAngle
    }
}
