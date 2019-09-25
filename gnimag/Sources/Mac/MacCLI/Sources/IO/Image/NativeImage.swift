//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image
import MacTestingTools

/// NativeImage is an Image effectively wrapping a CGImage using bitmap data.
/// Currently, the wrapped CGImage must have a BGRA pixel layout.
final class NativeImage: Image, ConvertibleToCGImage {
    /// The raw pixel data and CGImage.
    @usableFromInline
    let data: Data
    public let CGImage: CGImage

    /// Number of bytes per row of the raw pixel
    @usableFromInline
    let bytesPerRow: Int

    /// Default initializer.
    init(_ image: CGImage) {
        // Get raw pixel data
        data = image.dataProvider!.data! as Data
        bytesPerRow = image.bytesPerRow
        CGImage = image

        super.init(width: image.width, height: image.height)
    }

    /// Get the color value at the given pixel.
    @inlinable @inline(__always)
    override func color(at pixel: Pixel) -> Color {
        // Read pixel data (using BGRA layout)
        let offset = bytesPerRow * (height - 1 - pixel.y) + 4 * pixel.x
        let red = data[offset]
        let green = data[offset + 1]
        let blue = data[offset + 2]
        return Color(Double(red) / 255, Double(green) / 255, Double(blue) / 255)
    }
}
