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
            data: nil, // TODO: ist das default alles schwarz?
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
        let cgImage = (image as! ConvertibleToCGImage).CGImage

        let rgba = 4
        context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: cgImage.width * rgba,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )!

        // Draw image onto context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    }

    /// Create a new bitmap canvas where all pixels that have a small enough distance to a given color are filled in a specific (other) color.
    /// When "doDistanceBasedGreyscaleForOtherPixels" = true, the other pixels are white for really near and black for far away pixels (continuous). Else, all other pixels are black.
    public static func createByFillingAllPixels(_ fillColor: Color, whereDistanceTo comparingColor: Color, in image: Image, isAtMost threshold: Double, doDistanceBasedGreyscaleForOtherPixels: Bool = true) -> BitmapCanvas {
        let canvas = BitmapCanvas(width: image.width, height: image.height)

        // Fill pixel for pixel
        for x in 0 ..< image.width {
            for y in 0 ..< image.height {
                let pixel = Pixel(x, y)
                let diff = image.color(at: pixel).euclideanDifference(to: comparingColor)

                if diff <= threshold {
                    // Color matches: fill with "fillColor"
                    canvas.fill(pixel, with: fillColor)
                } else if doDistanceBasedGreyscaleForOtherPixels {
                    // Fill grey, distance-based
                    let p = (diff - threshold) / (1 - threshold) // p in (0, 1]
                    let color = Color(1-p, 1-p, 1-p)
                    canvas.fill(pixel, with: color)
                } // Else, leave pixel black as is
            }
        }

        return canvas
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
