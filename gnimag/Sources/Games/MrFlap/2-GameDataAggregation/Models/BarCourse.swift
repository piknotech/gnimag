//
//  Created by David Knothe on 23.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import GameKit

/// BarCourse bundles trackers for a single bar.

final class BarCourse {
    /// The state the bar is currently in.
    /// Only trackers with a "normal" state should be considered by prediction algorithms.
    private(set) var state: State
    enum State {
        case appearing, normal
    }

    // The angle and the center of the hole. yCenter is only used in state "normal".
    let angle: Circular<LinearTracker>
    let yCenter: LinearTracker

    // The constant width and hole size.
    let width: ConstantTracker
    let holeSize: ConstantTracker

    /// The hole size while the bar is appearing.
    /// Only used during the appearing state – once the hole size stays constant, the bar has stopped appearing and the "holeSize" tracker is used.
    let appearingHoleSize: LinearTracker

    /// The last y center position. Only used when no regression is available yet.
    var currentYCenter: Double?

    /// The shared playfield.
    private let playfield: Playfield

    // Default initializer.
    init(playfield: Playfield) {
        state = .normal
        angle = Circular(LinearTracker(maxDataPoints: 500))
        yCenter = LinearTracker(maxDataPoints: 500)
        width = ConstantTracker(maxDataPoints: 50)
        holeSize = ConstantTracker(maxDataPoints: 50)
        appearingHoleSize = LinearTracker(maxDataPoints: 50, tolerancePoints: 0) // No tolerance points because the appearing phase is really short
        self.playfield = playfield
    }

    // MARK: Updating

    /// Update the trackers with the values from the given bar.
    /// When one of the values does not match into the tracked course, discard the values and return an error.
    func update(with bar: Bar, at time: Double) -> Result<Void, UpdateError> {
        if case let .failure(error) = integrityCheck(with: bar, at: time) {
            return .failure(error)
        }

        angle.add(value: bar.angle, at: time)
        width.add(value: bar.width)

        switch state {
        case .appearing:
            appearingHoleSize.add(value: bar.holeSize, at: bar.angle)

        case .normal:
            holeSize.add(value: bar.holeSize, at: bar.angle)
            yCenter.add(value: bar.yCenter, at: bar.angle)
        }

        return .success(())
    }

    /// Check if the given values all match the trackers. If not, return an error.
    private func integrityCheck(with bar: Bar, at time: Double) -> Result<Void, UpdateError> {
        // TODO: %-werte global machen in AnalysisSettings
        guard !angle.hasRegression || angle.value(bar.angle, isValidWithTolerance: 2% * .pi, at: time) else {
            return .failure(.wrongAngle)
        }

        guard width.hasRegression || width.value(bar.width, isValidWithTolerance: 10% * width.average!) else {
            return .failure(.wrongWidth)
        }

        switch state {
        case .appearing:
            // If the appaering hole size does not match (but the angle and width did), the appearing state has ended; switch to normal state
            if appearingHoleSize.hasRegression && !appearingHoleSize.value(bar.holeSize, isValidWithTolerance: 5% * playfield.freeSpace, at: bar.angle) {
                print("state switch!")
                state = .normal
            }

        case .normal:
            guard !holeSize.hasRegression || holeSize.value(bar.holeSize, isValidWithTolerance: 5% * holeSize.average!) else {
                return .failure(.wrongHoleSize)
            }

            guard !yCenter.hasRegression || yCenter.value(bar.yCenter, isValidWithTolerance: 2% * playfield.freeSpace, at: bar.angle) else {
                return .failure(.wrongYCenter)
            }
        }

        return .success(())
    }

    /// Errors that can occur when calling "update" with malformed values.
    /// wrongYCenter or wrongHoleSize indicate that the bar may be disappearing.
    enum UpdateError: Error {
        case wrongAngle
        case wrongYCenter
        case wrongWidth
        case wrongHoleSize
    }
}
