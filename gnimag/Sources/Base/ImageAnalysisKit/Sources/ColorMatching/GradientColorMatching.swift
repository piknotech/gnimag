//
//  Created by David Knothe on 27.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation
import Image
import simd

/// A GradientColorMatch is a color match which allows any value between two color values (and an additional tolerance).
@usableFromInline
internal enum GradientColorMatching {
    /// The distance from a color to a color line segment.
    /// This is a simple point-line segment distance in R^3.
    @usableFromInline
    static func distance(from color: Color, to line: (start: Color, end: Color)) -> Double {
        let gradient = line.end.vector - line.start.vector
        let toStart = line.start.vector - color.vector
        let toEnd = line.end.vector - color.vector

        if dot(gradient, toStart) >= 0 {
            return length(toStart)
        } else if dot(gradient, toEnd) <= 0 {
            return length(toEnd)
        } else {
            return length(cross(gradient, toStart)) / length(gradient)
        }
    }
}

extension Color {
    /// The color vector in R^3.
    @_transparent @usableFromInline
    var vector: SIMD3<Double> {
        SIMD3<Double>(x: red, y: green, z: blue)
    }
}
