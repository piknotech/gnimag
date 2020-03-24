//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Image

/// GrayscaleImage is an Image effectively wrapping a CGImage using bitmap data.
/// The wrapped CGImage must be a grayscale image, i.e. have one byte per pixel.
internal class GrayscaleImage: Image {
    /// The raw pixel data and CGImage.
    let data: CFData

    private let _cgImage: CGImage
    public override var CGImage: CGImage { _cgImage }

    /// Single buffer for performant color reading.
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)

    /// Default initializer.
    init(_ image: CGImage) {
        // Get raw pixel data
        data = image.dataProvider!.data!
        _cgImage = image

        super.init(width: image.width, height: image.height)
    }

    /// Get the color value at the given pixel.
    @inlinable @inline(__always)
    override func color(at pixel: Pixel) -> Color {
        // Read pixel value
        let offset = width * (height - 1 - pixel.y) + pixel.x
        CFDataGetBytes(data, CFRangeMake(offset, 1), buf)
        
        let gray = Double(buf[0]) / 255
        return Color(gray, gray, gray)
    }
}
