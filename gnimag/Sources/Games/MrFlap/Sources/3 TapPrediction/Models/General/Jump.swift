//
//  Created by David Knothe on 23.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit

/// A jump from a start point to an end point.
struct Jump {
    let startPoint: Point
    let endPoint: Point

    /// The parabola going through startPoint and endPoint.
    let parabola: Polynomial

    var timeRange: SimpleRange<Double> {
        SimpleRange(from: startPoint.time, to: endPoint.time)
    }

    /// The minimal value the jump attains on its interval.
    var minimum: Double {
        min(startPoint.height, endPoint.height, parabola.apexValue)
    }

    /// The maximal value the jump attains on its interval.
    var maximum: Double {
        max(startPoint.height, endPoint.height, parabola.apexValue)
    }

    // MARK: Creating Jumps

    /// Calculate the jump from the given point with the given duration.
    static func from(startPoint: Point, duration: Double, jumping: JumpingProperties) -> Jump {
        let parabola = jumping.parabola.shiftedLeft(by: -startPoint.time) + startPoint.height
        let endTime = startPoint.time + duration
        let endHeight = parabola.at(endTime)
        return Jump(startPoint: startPoint, endPoint: Point(time: endTime, height: endHeight), parabola: parabola)
    }

    /// Calculate all jumps for the jump sequence defined by the given time distances, starting at the given point.
    static func jumps(forTimeDistances timeDistances: [Double], timeUntilEnd: Double, startPoint: Point, jumping: JumpingProperties) -> [Jump] {
        var result = [Jump]()
        var currentPoint = startPoint

        // Perform each jump
        for distance in timeDistances + [timeUntilEnd] {
            let jump = from(startPoint: currentPoint, duration: distance, jumping: jumping)
            result.append(jump)
            currentPoint = jump.endPoint
        }

        return result
    }
}

private extension Polynomial {
    /// The value of the apex. Only valid for parabolas.
    var apexValue: Value {
        at(-0.5 * b / a)
    }
}
