//
//  Created by David Knothe on 22.01.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// A time/height data point.
struct Point {
    let time: Double
    let height: Double

    static func +(lhs: Point, rhs: Point) -> Point {
        Point(time: lhs.time + rhs.time, height: lhs.height + rhs.height)
    }
}

/// An angle/height position.
struct Position {
    let x: Angle
    let y: Double
}
