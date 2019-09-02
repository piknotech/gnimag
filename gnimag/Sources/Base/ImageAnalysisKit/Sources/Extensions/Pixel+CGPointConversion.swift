//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

public extension Pixel {
    /// Convert the Pixel to a CGPoint.
    var CGPoint: CGPoint {
        Foundation.CGPoint(x: x, y: y)
    }
}

public extension CGPoint {
    /// Convert the CGPoint to a Pixel by rounding the values to the nearest integer.
    var nearestPixel: Pixel {
        Pixel(Int(round(x)), Int(round(y)))
    }

    /// Initialize the CGPoint from a Pixel.
    init(_ pixel: Pixel) {
        self = pixel.CGPoint
    }
}
