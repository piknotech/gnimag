//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Image

/// GrayscaleImage is an Image effectively wrapping a CGImage using bitmap data.
/// The wrapped CGImage must be a grayscale image, i.e. have one byte per pixel.
/// When initializing a GrayscaleImage, the whole pixel bitmap is read and stored for fast pixel-by-pixel-access.
internal class GrayscaleImage: Image {
    /// The raw pixel data.
    @usableFromInline
    private(set) var data: [UInt8]

    private let _cgImage: CGImage
    public override var CGImage: CGImage { _cgImage }

    /// Default initializer.
    init(_ image: CGImage) {
        // Get raw pixel data
        let cfData = image.dataProvider!.data!
        data = [UInt8](repeating: 0, count: CFDataGetLength(cfData))
        CFDataGetBytes(cfData, CFRangeMake(0, CFDataGetLength(cfData)), &data)

        _cgImage = image

        super.init(width: image.width, height: image.height)
    }

    /// Get the color value at the given pixel.
    @inlinable @inline(__always)
    override func color(at pixel: Pixel) -> Color {
        // Read pixel value
        let offset = width * (height - 1 - pixel.y) + pixel.x
        let gray = Double(data[offset]) / 255
        return Color(gray, gray, gray)
    }
}
