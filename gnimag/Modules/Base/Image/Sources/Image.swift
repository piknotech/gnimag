//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// Image describes an abstract image providing direct-pixel access.
/// Override this class to provide an implementation.
open class Image {
    public var width: Int { bounds.width }
    public var height: Int { bounds.height }
    public let bounds: Bounds

    /// Default initializer.
    public init(width: Int, height: Int) {
        bounds = Bounds(minX: 0, minY: 0, width: width, height: height)
    }

    /// Convenience method to check if a given pixel is inside the image.
    @inlinable @inline(__always)
    public final func contains(_ pixel: Pixel) -> Bool {
        bounds.contains(pixel)
    }

    /// Get the color at a given pixel.
    /// (0, 0) is the lower left corner, (width-1, height-1) is the upper-right corner.
    /// Precondition: the pixel must be inside the image.
    @inlinable @inline(__always)
    open func color(at pixel: Pixel) -> Color {
        fatalError("Image is an abstract class – please override this method.")
    }

    /// Return a CGImage which represents this image as good as possible.
    /// These CGImages should only be used for logging and debugging purposes.
    open var CGImage: CGImage {
        fatalError("Image is an abstract class – please override this property getter.")
    }
}
