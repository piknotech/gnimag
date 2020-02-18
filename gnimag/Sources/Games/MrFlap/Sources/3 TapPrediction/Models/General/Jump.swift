//
//  Created by David Knothe on 23.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import GameKit

/// A jump from a start point to an end point.
struct Jump {
    let startPoint: Point
    let endPoint: Point

    /// The parabola going through startPoint and endPoint.
    let parabola: Parabola

    var timeRange: SimpleRange<Double> {
        SimpleRange(from: startPoint.time, to: endPoint.time)
    }

    // MARK: Creating Jumps

    /// Calculate the jump from the given point with the given duration.
    static func from(startPoint: Point, duration: Double, jumping: JumpingProperties) -> Jump {
        // Calculate parabola with f(startPoint.x) = startPoint.y, f'(startPoint.x) = jumpVelocity
        let a = -1/2 * jumping.gravity
        let b = jumping.jumpVelocity - 2 * a * startPoint.time
        let c = startPoint.height - (a * startPoint.time * startPoint.time + b * startPoint.time)

        let parabola = Parabola(a: a, b: b, c: c)
        let endTime = startPoint.time + duration
        let endHeight = parabola.at(endTime)

        return Jump(startPoint: startPoint, endPoint: Point(time: endTime, height: endHeight), parabola: parabola)
    }

    /// Calculate all jumps for the jump sequence defined by the given time distances, starting at the given point.
    static func jumps(forTimeDistances timeDistances: [Double], timeUntilEnd: Double, startPoint: Point, jumping: JumpingProperties) -> [Jump] {
        var result = [Jump]()
        result.reserveCapacity(timeDistances.count + 1)

        var currentPoint = startPoint

        // Perform each jump
        for i in 0 ... timeDistances.count {
            // Performantly subscript `timeDistances + [timeUntilEnd]`
            let distance = (i == timeDistances.count)
                ? timeUntilEnd
                : timeDistances[i]

            let jump = from(startPoint: currentPoint, duration: distance, jumping: jumping)
            result.append(jump)
            currentPoint = jump.endPoint
        }

        return result
    }
}
