//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

/// Image describes an abstract image providing direct-pixel access.
/// Override this class to provide an implementation.

open class Image {
    public let width: Int
    public let height: Int

    /// Default initializer.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// Convenience method to check if a given pixel is inside the image.
    public final func contains(_ pixel: Pixel) -> Bool {
        return 0 <= pixel.x && pixel.x < width && 0 <= pixel.y && pixel.y < height
    }

    /// Get the color at a given pixel; (0, 0) is the upper left corner.
    /// Precondition: the pixel must be inside the image.
    /// TODO: wird es geinlined obwohl es in einem anderen target ist? - whole-module-optiminzations?
    @inline(__always)
    open func color(at pixel: Pixel) -> Color {
        fatalError("Image is an abstract class – please override this method.")
    }
}
