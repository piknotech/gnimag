//
//  Created by David Knothe on 18.02.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// An `Image` which is generated by resizing another `Image`.
/// We hereby use nearest-neighbor interpolation.
public final class ResizedImage: Image {
    @usableFromInline
    let image: Image

    /// The scale values which are applied when accessing a pixel.
    /// 0 is always mapped to 0, and 1 is mapped to xFactor or yFactor.
    @usableFromInline let xFactor: Double
    @usableFromInline let yFactor: Double
    private let resizedSize: CGSize

    /// Default initializer proving a new width and height.
    /// After resizing to the given non-integral width and height, the non-integral parts on the right and on the top are cut off. This allows maintaining the aspect ratio even for pictures with a very large or very small aspect ratio.
    public init(image: Image, newSize: CGSize) {
        self.image = image

        let newWidth = max(newSize.width, 1)
        let newHeight = max(newSize.height, 1)
        resizedSize = CGSize(width: newWidth, height: newHeight)

        xFactor = Double(image.width - 1) / Double(newWidth - 1)
        yFactor = Double(image.height - 1) / Double(newHeight - 1)

        super.init(width: Int(newWidth), height: Int(newHeight))
    }

    /// Access a pixel of the original image at an interpolated location.
    /// This is a nearest-neighbor interpolation, and only a single pixel will be accessed.
    public override func color(at pixel: Pixel) -> Color {
        let x = Int(round(Double(pixel.x) * xFactor))
        let y = Int(round(Double(pixel.y) * yFactor))
        return image.color(at: Pixel(x, y))
    }

    /// Resize the original CGImage.
    public override var CGImage: CGImage {
        image.CGImage.resize(to: resizedSize, interpolationQuality: .none)
    }
}

extension Image {
    public func resize(to size: CGSize) -> Image {
        ResizedImage(image: self, newSize: size)
    }

    public func resize(factor: CGFloat) -> Image {
        let size = CGSize(width: CGFloat(width) * factor, height: CGFloat(height) * factor)
        return resize(to: size)
    }
}