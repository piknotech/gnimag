//
//  Created by David Knothe on 16.02.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

extension CGImage {
    public func resize(to size: CGSize, interpolationQuality: CGInterpolationQuality = .high) -> CGImage {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        )!

        context.interpolationQuality = interpolationQuality
        context.draw(self, in: CGRect(origin: .zero, size: size))
        return context.makeImage()!
    }

    public func resize(factor: CGFloat, interpolationQuality: CGInterpolationQuality = .high) -> CGImage {
        let outputWidth = CGFloat(width) * factor
        let outputHeight = CGFloat(height) * factor
        return resize(to: CGSize(width: outputWidth, height: outputHeight), interpolationQuality: interpolationQuality)
    }
}
