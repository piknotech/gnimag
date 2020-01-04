//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common

/// BarProperties describe a moving bar with a hole in the middle.
struct BarProperties {
    /// A function getting the angular bar width (in radians) at a given height.
    /// The width is obviously not constant because, when converting from euclidean to angular coordinates, the same length further away from the center point maps to a shorter angle as the same length closer to the center point.
    let widthAtHeight: (Double) -> Double

    /// The constant vertical size of the moving hole.
    let holeSize: Double

    // TODO:
    // let yCenter: [LinearMovementAbschnitt]

    /// Angular horizontal speed (in radians per second).
    let xSpeed: Double

    /// The current x position of the bar.
    let xPosition: Angle

    // MARK: Conversion

    /// Convert a bar tracker into BarProperties.
    static func from(bar: BarCourse, with player: PlayerCourse, currentTime: Double) -> BarProperties? {
        guard let playerSize = player.size.average,
              let (speed, intercept) = convertBarAngleToTimeSystem(fromPlayerAngleSystem: player, bar: bar),
              let width = bar.width.average, let holeSize = bar.holeSize.average else { return nil }

        let xPosition = Angle(speed * currentTime + intercept)
        let widthAtHeight: (Double) -> Double = { height in
            2 * tan((width + playerSize) / height) // Extend bar width by player size
        }

        return BarProperties(widthAtHeight: widthAtHeight, holeSize: holeSize, xSpeed: speed, xPosition: xPosition)
    }

    /// Because, when tracking the bar's angle, time values are not the real time, but the player angle, this method converts the bar's angle back to normal time system.
    /// Returns slope and intercept of the linear angle function, in respect to time.
    private static func convertBarAngleToTimeSystem(fromPlayerAngleSystem player: PlayerCourse, bar: BarCourse) -> (slope: Double, intercept: Double)? {
        guard
            let (playerSlope, playerIntercept) = player.angle.tracker.slopeAndIntercept,
            let (barSlope, barIntercept) = bar.angle.tracker.slopeAndIntercept else { return nil }

        // playerAngle = playerSlope * t + playerIntercept
        // barAngle = barSlope * playerAngle + barIntercept
        //          = (barSlope * playerSlope) * t + (barSlope * playerIntercept + barIntercept)
        return (barSlope * playerSlope, barSlope * playerIntercept + barIntercept)
    }
}
