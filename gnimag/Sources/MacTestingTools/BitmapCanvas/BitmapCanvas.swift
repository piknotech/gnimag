//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

/// BitmapCanvas defines a drawing area which can be created by an Image.
/// It can be manipulated using methods similar like those of CGContext.
public final class BitmapCanvas {
    /// The underlying CGContext.
    private let context: CGContext

    // MARK: Initialization

    /// Create a blank canvas with the given width and height.
    public init(width: Int, height: Int) {
        let rgba = 4
        context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * rgba,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )!
    }

    /// Create a canvas directly from the given image.
    /// The image MUST be ConvertibleToCGImage.
    public init(image: Image) {
        let cgImage = (image as! ConvertibleToCGImage).toCGImage()

        let rgba = 4
        context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: cgImage.width * rgba,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        )!

        // Draw image onto context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    }

    // MARK: Drawing Operations

    /// Fill a single pixel with the given color.
    public func fill(_ pixel: Pixel, with color: Color, alpha: Double = 1) {
        context.setFillColor(color.NSColor(withAlpha: alpha).cgColor)
        context.fill(CGRect(x: pixel.x, y: pixel.y, width: 1, height: 1))
    }

    /// Draw the outline of a circle.
    public func drawCircle(center: CGPoint, radius: CGFloat, with color: Color, alpha: Double = 1, strokeWidth: Double = 1) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius)
        context.setLineWidth(CGFloat(strokeWidth))
        context.setStrokeColor(color.NSColor(withAlpha: alpha).cgColor)
        context.strokeEllipse(in: rect)
    }

    // MARK: Write to File

    /// Write the current canvas content to a file.
    public func write(to file: String) {
        let image = context.makeImage()!
        image.write(to: file)
    }
}
