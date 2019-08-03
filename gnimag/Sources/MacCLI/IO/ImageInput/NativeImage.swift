//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

/// NativeImage is an Image effectively wrapping a CGImage using bitmap data.
/// Currently, the wrapped CGImage must have a BGRA pixel layout.

final class NativeImage: Image {
    /// The raw pixel data.
    private let data: Data

    /// Number of bytes per row of the raw pixel data.
    private let bytesPerRow: Int

    /// Default initializer.
    init(_ image: CGImage) {
        // Check if BGRA layout matches
        guard image.bitmapInfo.contains(.byteOrder32Little) && image.alphaInfo == .premultipliedFirst else {
            fatalError("NativeImage.init – CGImage byte layout is incorrect (must be BGRA)")
        }

        // Get raw pixel data
        data = image.dataProvider!.data! as Data
        bytesPerRow = image.bytesPerRow

        super.init(width: image.width, height: image.height)
    }

    /// Get the color value at the given pixel.
    override func color(at pixel: Pixel) -> Color {
        // Read pixel data (using BGRA layout)
        let offset = bytesPerRow * pixel.y + 4 * pixel.x
        let red = data[offset]
        let green = data[offset + 1]
        let blue = data[offset + 2]
        return Color(Double(red) / 255, Double(green) / 255, Double(blue) / 255)
    }
}
