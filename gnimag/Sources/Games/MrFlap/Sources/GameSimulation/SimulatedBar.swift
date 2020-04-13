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
        let holeSize: CGFloat = 90 // 60
        let width: CGFloat = 30

        /// The (currently constant) yCenter.
        let yCenter: CGFloat

        /// The (currently constant) position of the bar.
        let angle: CGFloat

        /// Default initializer.
        init(angle: CGFloat, playfield: Playfield) {
            self.angle = angle

            let distance: CGFloat = 10
            let from = CGFloat(playfield.innerRadius) + holeSize / 2 + distance
            let to = CGFloat(playfield.fullRadius) - holeSize / 2 - distance
            yCenter = CGFloat.random(in: from ... to)
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
