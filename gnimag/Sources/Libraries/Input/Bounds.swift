//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Bounds describe the bounds of a rectangular region on an image.

public struct Bounds {
    public let minX: Int
    public let minY: Int
    public let width: Int
    public let height: Int

    /// Check if a pixel is inside the bounds.
    /// minX and minY are inide the bounds, whereas minX + width and minY + height are outside the bounds.
    public func contains(_ pixel: Pixel) -> Bool {
        minX <= pixel.x &&
        minY <= pixel.y &&
        pixel.x < minX + width &&
        pixel.y < minY + height
    }
}
