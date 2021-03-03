//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// Bounds describe the bounds of a rectangular region on an image.
/// Bounds are LLO, meaning that the origin (minX, minY) is in the lower-left corner.
public struct Bounds {
    public let minX: Int
    public let minY: Int
    public let width: Int
    public let height: Int

    /// One of the center pixels.
    public var center: Pixel {
        Pixel(minX + width / 2, minY + height / 2)
    }

    /// These Bounds as a CGRect instance.
    public var CGRect: CGRect {
        Foundation.CGRect(x: minX, y: minY, width: width, height: height)
    }

    /// Default initializer.
    public init(minX: Int, minY: Int, width: Int, height: Int) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }

    /// Initialize Bounds from a CGRect.
    /// If the rect is non-integral, Bounds will contain the rect.
    public init(rect: CGRect) {
        let rect = rect.integral
        self.init(minX: Int(rect.minX), minY: Int(rect.minY), width: Int(rect.width), height: Int(rect.height))
    }
    
    /// Check if a pixel is inside the bounds.
    /// minX and minY are inide the bounds, whereas minX + width and minY + height are outside the bounds.
    @_transparent
    public func contains(_ pixel: Pixel) -> Bool {
        minX <= pixel.x &&
        minY <= pixel.y &&
        pixel.x < minX + width &&
        pixel.y < minY + height
    }

    /// Inset the bounds by the given amount on each side.
    /// Providing a negative amount will make the bounds larger.
    public func inset(by inset: (dx: Int, dy: Int)) -> Bounds {
        return Bounds(
            minX: minX + inset.dx,
            minY: minY + inset.dy,
            width: width - 2 * inset.dx,
            height: height - 2 * inset.dy
        )
    }

    /// Intersect two bounds rectangles.
    public func intersection(with other: Bounds) -> Bounds {
        let intersection = CGRect.intersection(other.CGRect)

        if intersection.isNull {
            return Bounds(minX: 0, minY: 0, width: 0, height: 0)
        } else {
            return Bounds(minX: Int(intersection.minX), minY: Int(intersection.minY), width: Int(intersection.width), height: Int(intersection.height))
        }
    }
}
