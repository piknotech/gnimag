//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

/// GrayscaleImage is a wrapper around a grayscale CGImage having one byte per pixel.
/// When initializing a GrayscaleImage, the whole pixel bitmap is read and stored for fast pixel-by-pixel-access.
internal class GrayscaleImage {
    /// The raw pixel data.
    @usableFromInline
    private(set) var data: [UInt8]

    /// Default initializer.
    init(_ image: CGImage) {
        // Get raw pixel data
        let cfData = image.dataProvider!.data!
        data = [UInt8](repeating: 0, count: CFDataGetLength(cfData))
        CFDataGetBytes(cfData, CFRangeMake(0, CFDataGetLength(cfData)), &data)
    }
}

extension GrayscaleImage {
    /// The measure of pixel-wise identicality, i.e. the number of pixels which are exactly same (i.e. have the same grayscale value) divided by the total number of pixels.
    /// The images should have the same size.
    @inline(__always)
    func identicality(to other: GrayscaleImage) -> Double {
        let size = min(data.count, other.data.count)
        var equalPixels = 0

        for i in 0 ..< size {
            if data[i] == other.data[i] { equalPixels += 1 }
        }

        return Double(equalPixels) / Double(size)
    }
}
