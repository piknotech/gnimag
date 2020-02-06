//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
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
    /// The yCenter is translated into playfield coordinate system (adding the lower playfield radius).
    let yCenterMovementPortionsForTimeRange: (SimpleRange<Double>) -> [BasicLinearPingPongTracker.LinearSegmentPortion]

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double

    /// The current x position of the bar.
    let xPosition: Angle

    // MARK: Conversion

    /// Create BarProperties from the given bar tracker.
    init?(bar: BarCourse, with player: PlayerCourse, playfield: PlayfieldProperties, currentTime: Double) {
        guard let converter = PlayerAngleConverter(player: player) else { return nil }

        guard
            let playerSize = player.size.average,
            let width = bar.width.average,
            let holeSize = bar.holeSize.average,
            let angleByPlayerAngle = bar.angle.tracker.regression else { return nil }

        self.holeSize = holeSize

        // widthAtHeight implementation
        angularWidthAtHeight = { height in
            2 * tan(0.5 * (width + playerSize) / height) // Extend bar width by player size
        }

        // Inverse of widthAtHeight
        heightAtAngularWidth = { x in
            0.5 * (width + playerSize) / atan(x / 2)
        }

        // Check if yCenterMovementPortionsForTimeRange is non-nil
        let guesses = BarCourse.momventBoundCollector.guesses(for: bar)
        guard bar.yCenter.segmentPortionsForFutureTimeRangeAvailable(guesses: guesses) else { return nil }

        // yCenterMovementPortionsForTimeRange implementation
        yCenterMovementPortionsForTimeRange = { timeRange in
            let angularRange = converter.angleBasedRange(from: timeRange)
            let result = bar.yCenter.segmentPortionsForFutureTimeRange(angularRange, guesses: guesses) ?? []
            let timeBasedResult = result.map(converter.timeBasedLinearSegmentPortion)

            // Convert into playfield coordinate system
            return timeBasedResult.map { portion in
                let newLine = portion.line + playfield.offsetToBarCoordinateSystem
                return BasicLinearPingPongTracker.LinearSegmentPortion(index: portion.index, timeRange: portion.timeRange, line: newLine)
            }
        }

        // Get speed and current position
        let angleByTime = converter.timeBasedLinearFunction(from: angleByPlayerAngle)
        xSpeed = angleByTime.slope
        xPosition = Angle(angleByTime.at(currentTime))
    }
}
