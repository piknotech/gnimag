//
//  Created by David Knothe on 14.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import GameKit
import TestingTools

extension JumpSequencePlot {
    /// A jump from a start point to an end point.
    struct Jump {
        let startPoint: Point
        let endPoint: Point
        let parabola: Polynomial

        /// The start point as ScatterDataPoint.
        var scatterStartPoint: ScatterDataPoint {
            ScatterDataPoint(x: startPoint.time, y: startPoint.height)
        }

        /// The end point as ScatterDataPoint.
        var scatterEndPoint: ScatterDataPoint {
            ScatterDataPoint(x: endPoint.time, y: endPoint.height)
        }

        /// The ScatterStrokable representing the parabola.
        var scatterStrokable: ScatterStrokable {
            QuadCurveScatterStrokable(parabola: parabola, drawingRange: SimpleRange(from: startPoint.time, to: endPoint.time))
        }
    }

    /// Calculate the jump from the given point with the given duration.
    static func jump(from startPoint: Point, duration: Double, jumping: JumpingProperties) -> Jump {
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
            let jump = self.jump(from: currentPoint, duration: distance, jumping: jumping)
            result.append(jump)
            currentPoint = jump.endPoint
        }

        return result
    }
}
