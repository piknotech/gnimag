//
//  Created by David Knothe on 23.06.19.
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
        angle = Circular(LinearTracker())
        yCenter = LinearTracker()
        width = ConstantTracker()
        holeSize = ConstantTracker()
        appearingHoleSize = LinearTracker(tolerancePoints: 0) // No tolerance points because the appearing phase is really short
        self.playfield = playfield
    }

    // MARK: Updating

    /// Update the trackers with the values from the given bar.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with bar: Bar, at time: Double) {
        angle.add(value: bar.angle, at: time)
        width.add(value: bar.width)

         // Map angle from [0, 2pi) to R
        let linearAngle = angle.linearify(bar.angle, at: time)

        switch state {
        case .appearing:
            appearingHoleSize.add(value: bar.holeSize, at: linearAngle)

        case .normal:
            holeSize.add(value: bar.holeSize, at: linearAngle)
            yCenter.add(value: bar.yCenter, at: linearAngle)
        }
    }

    /// Check if all given values match the trackers.
    /// NOTE: This changes the state from `.appearing` to `.normal` when necessary.
    func integrityCheck(with bar: Bar, at time: Double) -> Bool {
        guard angle.is(bar.angle, at: time, validWith: .absolute(tolerance: 2% * .pi)) else {
            return false
        }

        guard width.is(bar.width, validWith: .relative(tolerance: 10%)) else {
            return false
        }

        switch state {
        case .appearing:
            // If the appearing hole size does not match (but the angle and width did), the appearing state has ended; switch to normal state
            if !appearingHoleSize.is(bar.holeSize, at: bar.angle, validWith: .absolute(tolerance: 5% * playfield.freeSpace)) {
                print("state switch!")
                state = .normal
            }

        case .normal:
            guard holeSize.is(bar.width, at: bar.angle, validWith: .relative(tolerance: 5%)) else {
                return false
            }

            guard yCenter.is(bar.yCenter, at: bar.angle, validWith: .absolute(tolerance: 2% * playfield.freeSpace)) else {
                return false
            }
        }

        return true
    }
}
