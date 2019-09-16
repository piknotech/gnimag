//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// Delta describes the distance between two Pixels, using integral values.
public struct Delta: Equatable, CustomStringConvertible {
    public var dx: Int
    public var dy: Int
    
    /// Default initializer.
    public init(_ dx: Int, _ dy: Int) {
        self.dx = dx
        self.dy = dy
    }
    
    /// Rotate the delta by a given rotation.
    public func rotated(by rotation: Rotation) -> Delta {
        switch rotation {
        case .up: return Delta(dx, dy)
        case .down: return Delta(-dx, -dy)
        case .left: return Delta(dy, -dx)
        case .right: return Delta(-dy, dx)
        }
    }
    
    /// Multiply the delta with a scalar.
    public func scaled(by scalar: Int) -> Delta {
        return Delta(dx * scalar, dy * scalar)
    }
    
    // MARK: Equatable
    /// Compare two delta instances.
    public static func ==(lhs: Delta, rhs: Delta) -> Bool {
        return lhs.dx == rhs.dx && lhs.dy == rhs.dy
    }
    
    // MARK: CustomStringConvertible
    /// Describe the delta.
    public var description: String {
        return "Delta(\(dx) | \(dy))"
    }
    
    // MARK: Static members
    /// The (0, 0) delta.
    public static let zero = Delta(0, 0)
}

// MARK: - Arithmetic

/// Add a delta to a point.
public func +(point: Pixel, delta: Delta) -> Pixel {
    return Pixel(point.x + delta.dx, point.y + delta.dy)
}

/// Substract a delta from a point.
public func -(point: Pixel, delta: Delta) -> Pixel {
    return Pixel(point.x - delta.dx, point.y - delta.dy)
}

/// Calculate the delta between two points.
public func -(lhs: Pixel, rhs: Pixel) -> Delta {
    return Delta(lhs.x - rhs.x, lhs.y - rhs.y)
}

/// Negate a delta.
public prefix func -(delta: Delta) -> Delta {
    return Delta(-delta.dx, -delta.dy)
}
