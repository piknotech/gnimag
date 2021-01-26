//
//  Created by David Knothe on 23.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation
import Image

/// OCRComponent describes a component (i.e. a possible character or character part).
/// A component is inside a rectangular subregion of an image. The component consists of one or multiple pixels inside this subregion.
internal struct OCRComponent {
    /// The bounding region of this component, respective to the original image.
    /// This is the smallest rectangular region which contains all pixels of this component.
    let region: Bounds

    /// All pixels the component consists of.
    /// The pixel locations are relative to the original image, i.e. all pixels are inside `region`.
    let pixels: [Pixel]

    /// Default initializer.
    init(pixels: [Pixel]) {
        self.pixels = pixels

        var aabb = SmallestAABB.containing(pixels).rect
        aabb.size.width += 1 // Pixels have a size of 1x1 -> extend aabb
        aabb.size.height += 1
        region = Bounds(rect: aabb)
    }

    /// Combine this component with another one.
    func combine(with other: OCRComponent) -> OCRComponent {
        OCRComponent(pixels: pixels + other.pixels)
    }

    /// The pixels translated into the local coordinate system.
    private var localPixels: [Pixel] {
        pixels.map { $0 - Delta(region.minX, region.minY) }
    }

    // MARK: CGImage

    /// Convert the bitmap to a black-and-white CGImage.
    /// White means the pixel is inside the bitmap.
    var CGImage: CGImage {
        let gray = 1 // Could also RGBA etc.
        var rawData = [UInt8](repeating: 0, count: gray * region.width * region.height)

        for pixel in localPixels {
            let offset = gray * (region.width * (region.height - 1 - pixel.y) + pixel.x)
            rawData[offset] = 255 // Only 1 value (gray) per pixel
        }

        return CGImage(from: rawData)
    }

    /// Convert a raw grayscale pixel array into a grayscale CGImage.
    private func CGImage(from rawData: [UInt8]) -> CGImage {
        let gray = 1
        return Foundation.CGImage(
            width: region.width,
            height: region.height,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * gray,
            bytesPerRow: region.width * gray,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: CGDataProvider(data: CFDataCreate(nil, rawData, rawData.count)!)!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }
}
