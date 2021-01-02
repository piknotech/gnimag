//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// NativeImage is an Image effectively wrapping a CGImage using bitmap data.
public final class NativeImage: Image {
    /// The raw pixel data and CGImage.
    @usableFromInline
    let data: CFData

    private let _cgImage: CGImage
    public override var CGImage: CGImage { _cgImage }

    @usableFromInline
    let colorFromBuf: (UnsafeMutablePointer<UInt8>) -> Color

    /// Number of bytes per row of the raw pixel.
    @usableFromInline
    let bytesPerRow: Int

    /// Single buffer for performant color reading.
    @usableFromInline
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)

    /// Default initializer.
    public init(_ image: CGImage) {
        // Get raw pixel data
        data = image.dataProvider!.data!
        bytesPerRow = image.bytesPerRow
        _cgImage = image

        // Read pixel format
        guard let pixelFormat = image.bitmapInfo.pixelFormat else {
            exit(withMessage: "NativeImage – couldn't read pixel format of image. BitmapInfo: \(image.bitmapInfo.rawValue)")
        }

        switch pixelFormat {
        case .abgr: colorFromBuf = { buf in Color(red: buf[3], green: buf[2], blue: buf[1]) }
        case .argb: colorFromBuf = { buf in Color(red: buf[1], green: buf[2], blue: buf[3]) }
        case .bgra: colorFromBuf = { buf in Color(red: buf[2], green: buf[1], blue: buf[0]) }
        case .rgba: colorFromBuf = { buf in Color(red: buf[0], green: buf[1], blue: buf[2]) }
        }

        super.init(width: image.width, height: image.height)
    }

    /// Get the color value at the given pixel.
    @inlinable @inline(__always)
    public override func color(at pixel: Pixel) -> Color {
        let offset = bytesPerRow * (height - 1 - pixel.y) + 4 * pixel.x

        CFDataGetBytes(data, CFRangeMake(offset, 4), buf)
        return colorFromBuf(buf)
    }
}
