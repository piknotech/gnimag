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
    let data: CFData
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
        
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
        CFDataGetBytes(data, CFRangeMake(offset, 3), buf)
        return Color(Double(buf[0]) / 255, Double(buf[1]) / 255, Double(buf[2]) / 255)
    }
}
