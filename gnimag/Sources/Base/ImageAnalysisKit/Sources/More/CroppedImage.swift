//
//  Created by David Knothe on 21.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

/// An image which emerges by cropping another image to a given rect.
public final class CroppedImage: Image {
    /// The original image.
    @usableFromInline
    let image: Image

    /// The rectangle which has been cropped out.
    /// This is a sub-rectangle of `image.bounds`; also, its size matches with the size of `self.bounds`
    @usableFromInline
    let cropRectangle: Bounds

    /// Default initializer.
    public init(image: Image, cropRectangle: Bounds) {
        self.image = image

        // Intersect `image.bounds` with `cropRectangle` (as it may be outside of `image.bounds`)
        self.cropRectangle = image.bounds.intersection(with: cropRectangle)

        super.init(width: cropRectangle.width, height: cropRectangle.height)
    }

    /// Return the color of the original image at the translated location.
    @inlinable @inline(__always)
    public override func color(at pixel: Pixel) -> Color {
        let translated = pixel + Delta(cropRectangle.minX, cropRectangle.minY)
        return image.color(at: translated)
    }

    /// Crop the original CGImage (if existing) to the specified crop rectangle.
    public override var CGImage: CGImage? {
        image.CGImage?.cropping(to: cropRectangle.CGRect)
    }
}

public extension Image {
    /// Crop the image to the given rect.
    /// Attention: when `cropBounds` is not fully contained inside `self.bounds`, the size of the resulting image is smaller than `cropBounds.size`.
    func cropped(to cropBounds: Bounds) -> CroppedImage {
        CroppedImage(image: self, cropRectangle: cropBounds)
    }

    /// Inset the image by the given amount on each side.
    func inset(by inset: (dx: Int, dy: Int)) -> CroppedImage {
        cropped(to: bounds.inset(by: inset))
    }
}
