//
//  Created by David Knothe on 10.12.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import GameKit

/// PointsTracker calculates the points the player has currently reached in the input images.
/// Therefore, PointsTracker uses the player angle tracker.
internal class PointsTracker {
    /// The angle the player had initially (with 0 points).
    private var startAngle: Double!
    private var lastAngle: Double!

    init() {
    }

    /// Set the start angle.
    func setInitialAngle(_ angle: Double) {
        startAngle = angle
    }

    /// Update using the values from the player tracker.
    func update(tracker: PlayerTracker, time: Double) {
        guard let angle = tracker.angle.regression?.at(time) ?? tracker.angle.values.last else { return }
        lastAngle = angle
    }

    /// The current points (at the last updated image time).
    var points: Int {
        if let start = startAngle, let last = lastAngle {
            let diff = abs(last - start)
            return max(0, Int(diff / (2 * .pi)))
        } else {
            return 0 // Not enough data points --> 0 points
        }
    }
}
