//
//  Created by David Knothe on 24.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Image

internal enum ComponentCombinationStrategy {
    static let none: (OCRComponent, OCRComponent) -> Bool = { a, b in false }

    /// Combine when the (x-values-specific) overlap range is large enough in relation to the width of the smaller component.
    /// `requiredOverlap` is in [0, 1] and defines how much relative overlap must be present.
    static func verticalOverlay(requiredOverlap: Double) -> (OCRComponent, OCRComponent) -> Bool {
        return { a, b in
            let smallerWidth = min(a.region.width, b.region.width)
            let overlap = a.region.xRange.intersection(with: b.region.xRange).size
            return overlap / Double(smallerWidth) >= requiredOverlap
        }
    }
}

internal extension Bounds {
    var xRange: SimpleRange<Double> {
        SimpleRange(from: Double(minX), to: Double(minX + width))
    }

    var yRange: SimpleRange<Double> {
        SimpleRange(from: Double(minY), to: Double(minY + height))
    }
}

internal extension CGImage {
    /// Possibilities for how to scale and align an image to a size with a different aspect ratio.
    enum ScaleMode {
        case aspectFitCenter
    }

    /// Scale the image to the given size and return a GrayscaleImage.
    func scaled(toWidth scaledWidth: Int, height scaledHeight: Int, mode: ScaleMode) -> GrayscaleImage {
        let gray = 1
        let context = CGContext(
            data: nil,
            width: scaledWidth,
            height: scaledHeight,
            bitsPerComponent: 8,
            bytesPerRow: scaledWidth * gray,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: 0
        )!

        context.interpolationQuality = .none

        context.setFillColor(.black)
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))

        // Scale image according to mode
        switch mode {
        case .aspectFitCenter:
            let ratio = min(Double(context.width) / Double(width), Double(context.height) / Double(height))
            let center = CGPoint(x: Double(context.width) / 2, y: Double(context.height) / 2)
            let size = CGSize(width: Double(width) * ratio, height: Double(height) * ratio)
            let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
            let rect = CGRect(origin: origin, size: size)
            context.draw(self, in: rect)
        }

        return GrayscaleImage(context.makeImage()!)
    }
}
