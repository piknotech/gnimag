//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Image

/// Direction defines a simple direction used in pixel-wise operations.
/// Direction can also be used as a rotation (going counter-clockwise), using multiples of 90°.
public enum Direction {
    case up, down, left, right
    
    /// All valid directions.
    private static var all = [Direction.up, .down, .left, .right]
    
    /// The (x, y) delta that defines this direction.
    public var delta: Delta {
        switch self {
        case .up: return Delta(0, -1) // As rotation: 0°
        case .left: return Delta(-1, 0) // As rotation: 90°
        case .down: return Delta(0, 1) // As rotation: 180°
        case .right: return Delta(1, 0) // As rotation: 270°
        }
    }

    /// Rotate the direction by a given rotation.
    public func rotated(by rotation: Rotation) -> Direction {
        return .from(delta: delta.rotated(by: rotation))
    }
    
    /// Construct the Direction from a given delta.
    /// Assumes the delta is valid (i.e. has the length 1).
    private static func from(delta: Delta) -> Direction {
        return Direction.all.first { $0.delta == delta }!
    }
}

public typealias Rotation = Direction
