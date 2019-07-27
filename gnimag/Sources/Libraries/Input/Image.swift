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

    /// Convenience method to check if a given point is inside the image.
    public final func contains(_ point: Point) -> Bool {
        return 0 <= point.x && point.x < width && 0 <= point.y && point.y < height
    }

    /// Get the color at a given point; (0, 0) is the upper left corner.
    /// Precondition: the pixel must be inside the image.
    /// TODO: wird es geinlined obwohl es in einem anderen target ist? - whole-module-optiminzations?
    @inline(__always)
    open func color(at point: Point) -> Color {
        fatalError("Image is an abstract class – please override this method.")
    }
}
