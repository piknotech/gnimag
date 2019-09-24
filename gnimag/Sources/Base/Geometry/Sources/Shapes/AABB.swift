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

    /// Initialize with the smallest AABB that contains the given (non-empty) set of points.
    /// This runs in O(n) time.
    public init(containing points: [CGPoint]) {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }

        let minX = xs.min()!, minY = ys.min()!
        let maxX = xs.max()!, maxY = ys.max()!

        let origin = CGPoint(x: minX, y: minY)
        let size = CGSize(width: maxX - minX, height: maxY - minY)
        self.init(rect: CGRect(origin: origin, size: size))
    }

    public var center: CGPoint { .init(x: rect.midX, y: rect.midY) }
    public var width: CGFloat { rect.width }
    public var height: CGFloat { rect.height }
}

extension AABB: Shape {
    /// Calculate the unsigned distance to a point.
    public func distance(to point: CGPoint) -> CGFloat {
        if contains(point) {
            let dx1 = point.x - rect.minX, dx2 = rect.maxX - point.x
            let dy1 = point.y - rect.minY, dy2 = rect.maxY - point.y
            return min(dx1, dx2, dy1, dy2)
        }

        // Distance calculation for points outside the rectangle
        let dx = max(abs(point.x - center.x) - width / 2, 0)
        let dy = max(abs(point.y - center.y) - height / 2, 0)
        return sqrt(dx * dx + dy * dy)
    }

    /// Check if the point is inside the shape.
    /// NOTE: This does not use CGRect.contains because it does not fully consider the rect's borders.
    public func contains(_ point: CGPoint) -> Bool {
        rect.minX <= point.x &&
        rect.minY <= point.y &&
        point.x <= rect.maxX &&
        point.y <= rect.maxY
    }

    public var boundingBox: AABB { self }
}
