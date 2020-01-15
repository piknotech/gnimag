//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// BarProperties describe a moving bar with a hole in the middle.
struct BarProperties {
    /// A function getting the angular bar width (in radians) at a given height.
    /// The width is obviously not constant because, when converting from euclidean to angular coordinates, the same length further away from the center point maps to a shorter angle as the same length closer to the center point.
    let angularWidthAtHeight: (Double) -> Double

    /// The inverse of the `angularWidthAtHeight` function.
    let heightAtAngularWidth: (Double) -> Double

    /// The constant vertical size of the moving hole.
    let holeSize: Double

    /// A function mapping a time range to the movement that is performed by the bar's yCenter during that range.
    let yCenterMovementPortionsForAngularRange: (SimpleRange<Double>) -> [BasicLinearPingPongTracker.LinearSegmentPortion]

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double

    /// The current x position of the bar.
    let xPosition: Angle

    // MARK: Conversion

    /// Convert a bar tracker into BarProperties.
    static func from(bar: BarCourse, with player: PlayerCourse, currentTime: Double) -> BarProperties? {
        guard let converter = PlayerAngleConverter.from(player: player) else { return nil }

        guard
            let playerSize = player.size.average,
            let width = bar.width.average,
            let holeSize = bar.holeSize.average,
            let angleByPlayerAngle = bar.angle.tracker.regression else { return nil }

        // widthAtHeight implementation
        let widthAtHeight: (Double) -> Double = { height in
            2 * tan((width + playerSize) / height) // Extend bar width by player size
        }

        // Inverse of widthAtHeight
        let heightAtWidth: (Double) -> Double = { x in
            (width + playerSize) / atan(x / 2)
        }

        // yCenterMovementPortionsForAngularRange implementation
        let yCenterMovement: (SimpleRange<Double>) -> [BasicLinearPingPongTracker.LinearSegmentPortion] = { timeRange in
            let angularRange = converter.angleBasedRange(from: timeRange)
            let guesses = BarCourse.momventBoundCollector.guesses(for: bar)
            let result = bar.yCenter.segmentPortionsForFutureTimeRange(angularRange, guesses: guesses) ?? []
            return result.map(converter.timeBasedLinearSegmentPortion)
        }

        // Get speed and current position
        let angleByTime = converter.angleBasedLinearFunction(from: angleByPlayerAngle)
        let currentAngle = Angle(angleByTime.at(currentTime))

        return BarProperties(angularWidthAtHeight: widthAtHeight, heightAtAngularWidth: heightAtWidth, holeSize: holeSize, yCenterMovementPortionsForAngularRange: yCenterMovement, xSpeed: angleByTime.slope, xPosition: currentAngle)
    }
}
