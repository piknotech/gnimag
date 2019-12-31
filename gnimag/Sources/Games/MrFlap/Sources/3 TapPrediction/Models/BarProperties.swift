//
//  Created by David Knothe on 31.12.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// BarProperties describe a moving bar with a hole in the middle.
struct BarProperties {
    /// A function getting the angular bar width (in radians) at a given height.
    /// The width is obviously not constant because, when converting from euclidean to angular coordinates, the same length further away from the center point maps to a shorter angle as the same length closer to the center point.
    var widthAtHeight: (Double) -> Double

    /// The constant vertical size of the moving hole.
    var holeSize: Double

    // TODO:
    // public var yCenter: [LinearMovementAbschnitt]

    /// Angular horizontal speed (in radians per second).
    var xSpeed: Double
}
