//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An axis-aligned bounding box.
public struct AABB {
    /// The bounds of the box. The bounds are LLO, meaning the origin is in the lower left corner.
    public let rect: CGRect

    /// Default initializer.
    public init(rect: CGRect) {
        self.rect = rect
    }

    /// Convenience initializer.
    public init(center: CGPoint, width: CGFloat, height: CGFloat) {
        rect = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    public var center: CGPoint { .init(x: rect.midX, y: rect.midY) }
    public var width: CGFloat { rect.width }
    public var height: CGFloat { rect.height }
}

extension AABB: Shape {
    /// Calculate the unsigned distance to a point.
    public func distance(to point: CGPoint) -> CGFloat {
        let dx = max(abs(point.x - center.x) - width / 2, 0)
        let dy = max(abs(point.y - center.y) - height / 2, 0)
        return sqrt(dx * dx + dy * dy)
    }
}
