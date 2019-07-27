//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Point represents a point on an image, only consisting of integral values.

public struct Point {
    public var x: Int
    public var y: Int
    
    /// Default initializer.
    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

extension Point: Equatable {
    /// Compare two point instances.
    public static func ==(lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension Point: CustomStringConvertible {
    /// Describe the point.
    public var description: String {
        return "Point(\(x) , \(y))"
    }
}
