//
//  Created by David Knothe on 13.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import GameKit
import Geometry

extension MrFlapGameSimulation {
    /// A simulated bar object.
    struct Bar {
        let holeSize: CGFloat = 60
        let width: CGFloat = 30

        /// The current game time.
        private var currentTime: Double = 0

        /// The position of the bar.
        var angle: CGFloat { CGFloat(angleFunction(currentTime)) }
        private let angleFunction: LinearFunction

        /// The yCenter movement.
        var yCenter: CGFloat { CGFloat(yCenterFunction(currentTime)) }
        private let yCenterFunction: Function
        
        /// Default initializer.
        init(angle: Double, angularSpeed: Double, yCenterPeriodDuration: Double, playfield: Playfield) {
            angleFunction = LinearFunction(slope: angularSpeed, intercept: angle)

            // yCenter
            let distance: Double = 10
            let min = playfield.innerRadius + Double(holeSize) / 2 + distance
            let max = playfield.fullRadius - Double(holeSize) / 2 - distance
            let start = Double.random(in: min...max)
            let speed = 2 * (max - min) / yCenterPeriodDuration

            yCenterFunction = FunctionWrapper { t in
                let t = t.truncatingRemainder(dividingBy: yCenterPeriodDuration)
                var pos = start + t * speed
                if pos > max { pos = 2 * max - pos }
                if pos < min { pos = 2 * min - pos }
                return pos
            }
        }

        /// Update the bar by updating its current time and therefore its position.
        mutating func update(currentTime: Double) {
            self.currentTime = currentTime
        }

        /// Return the OBBs which are required for drawing this bar in a reference playfield.
        func obbs(forDrawingIn playfield: Playfield) -> [OBB] {
            // Lower OBB
            let lowerHeight = yCenter - holeSize / 2
            let lowerAABBAt0Corners = [CGPoint(x: 0, y: width / 2), CGPoint(x: lowerHeight, y: -width / 2)]
            let lowerAABBAt0 = AABB(containing: lowerAABBAt0Corners.map { playfield.center + $0 })
            let lowerOBB = lowerAABBAt0.rotated(by: angle, around: playfield.center)

            // Upper OBB
            let upperAABBAt0Corners = [CGPoint(x: lowerHeight + holeSize, y: width / 2), CGPoint(x: CGFloat(playfield.fullRadius), y: -width / 2)]
            let upperAABBAt0 = AABB(containing: upperAABBAt0Corners.map { playfield.center + $0 })
            let upperOBB = upperAABBAt0.rotated(by: angle, around: playfield.center)

            return [lowerOBB, upperOBB]
        }
    }
}
