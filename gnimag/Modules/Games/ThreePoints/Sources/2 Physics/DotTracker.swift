//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import GameKit

/// DotTracker tracks the movement of a single dot.
final class DotTracker {
    let orphanage = OrphanageDetector(maxFramesWithoutUpdate: 3)

    let yCenter: LinearTracker
    let radius: ConstantTracker

    /// Default initializer.
    init(dot: AnalysisResult.Dot) {
        yCenter = LinearTracker(tolerancePoints: 2, tolerance: .absolute(20% * dot.radius))
        radius = ConstantTracker(tolerancePoints: 1, tolerance: .absolute(20% * dot.radius))
    }

    /// Check if all given values match the trackers.
    func integrityCheck(with dot: AnalysisResult.Dot, at time: Double) -> Bool {
        yCenter.isDataPointValid(value: dot.yCenter, time: time) && radius.isValueValid(dot.radius)
    }

    /// Update the trackers with the values from the given dot.
    /// Only call this AFTER a successful `integrityCheck`.
    func update(with dot: AnalysisResult.Dot, at time: Double) {
        orphanage.markAsValid()

        yCenter.add(value: dot.yCenter, at: time)
        radius.add(value: dot.radius)
    }
}

extension DotTracker: Hashable {
    static func == (lhs: DotTracker, rhs: DotTracker) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
}
