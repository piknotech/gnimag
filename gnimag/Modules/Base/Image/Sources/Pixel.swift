//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common

/// Pixel represents a point on an image, only consisting of integral values.
/// (0, 0) is the lower left corner.
public struct Pixel: HasDistance {
    public var x: Int
    public var y: Int
    
    /// Default initializer.
    @_transparent
    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    /// The euclidean distance between this pixel and another pixel.
    @_transparent
    public func distance(to other: Pixel) -> Double {
        sqrt(Double((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)))
    }
}

extension Pixel: Equatable {
    /// Compare two pixel instances.
    public static func ==(lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension Pixel: CustomStringConvertible {
    /// Describe the pixel.
    public var description: String {
        return "(\(x), \(y))"
    }
}

extension Pixel: Hashable {
}
