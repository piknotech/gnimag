//
//  Created by David Knothe on 06.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Cocoa
import Common
import Foundation
import Image

/// BitmapCanvas defines a drawing area which can be created by an Image.
/// It can be manipulated using methods similar like those of CGContext.
public final class BitmapCanvas {
    /// The underlying CGContext.
    internal let context: CGContext

    // MARK: Initialization
    /// Create an empty (= transparent) canvas with the given width and height.
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

    /// Create a canvas directly from the given Image.
    /// The image MUST be ConvertibleToCGImage.
    public convenience init(image: Image) {
        let CGImage = (image as! ConvertibleToCGImage).CGImage
        self.init(CGImage: CGImage)
    }

    /// Create a canvas directly from the given CGImage.
    public init(CGImage: CGImage) {
        let rgba = 4
        context = CGContext(
            data: nil,
            width: CGImage.width,
            height: CGImage.height,
            bitsPerComponent: 8,
            bytesPerRow: CGImage.width * rgba,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImage.bitmapInfo.rawValue
        )!

        // Draw image onto context
        context.draw(CGImage, in: CGRect(x: 0, y: 0, width: CGImage.width, height: CGImage.height))
    }

    /// Create a canvas by drawing an NSView onto its context.
    /// The view should have integral side lengths.
    public convenience init(view: NSView, background: NSColor? = nil) {
        self.init(width: Int(view.bounds.width), height: Int(view.bounds.height))

        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        background?.drawSwatch(in: view.bounds)

        // Flip context before drawing the view
        context.saveGState()
        context.translateBy(x: 0, y: view.bounds.height)
        context.scaleBy(x: 1, y: -1)
        view.draw(view.bounds)
        context.restoreGState()
    }

    /// Create a new bitmap canvas where all pixels that have a small enough distance to a given color are filled in a specific (other) color.
    /// When "createDistanceBasedGreyscaleForOtherPixels" = true, the other pixels are white for really near and black for far away pixels (continuous). Else, all other pixels are black.
    public static func createByFillingAllPixels(_ fillColor: Color, whereDistanceTo comparingColor: Color, in image: Image, isAtMost threshold: Double, createDistanceBasedGreyscaleForOtherPixels: Bool = true) -> BitmapCanvas {
        let canvas = BitmapCanvas(width: image.width, height: image.height)

        // Fill pixel for pixel
        for x in 0 ..< image.width {
            for y in 0 ..< image.height {
                let pixel = Pixel(x, y)
                let diff = image.color(at: pixel).distance(to: comparingColor)

                // Fill pixel either with `fillColor`, gray or `.black`.
                if diff <= threshold {
                    canvas.fill(pixel, with: fillColor)
                }
                else if createDistanceBasedGreyscaleForOtherPixels {
                    let p = (diff - threshold) / (1 - threshold) // p in (0, 1]
                    let color = Color(1-p, 1-p, 1-p)
                    canvas.fill(pixel, with: color)
                }
                else {
                    canvas.fill(pixel, with: .black)
                }
            }
        }

        return canvas
    }

    /// Return a new canvas which contains the contents of the cut rectangle.
    public func cut(to bounds: Bounds) -> BitmapCanvas {
        let new = BitmapCanvas(width: bounds.width, height: bounds.height)
        new.context.draw(CGImage, in: CGRect(x: -bounds.minX, y: -bounds.minY, width: context.width, height: context.height))
        return new
    }

    // MARK: Simple Color Operations
    /// Fill the whole canvas with the given color.
    @discardableResult
    public func background(_ color: Color, alpha: Double = 1) -> BitmapCanvas {
        context.setFillColor(color.CGColor(withAlpha: alpha))
        context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
        return self
    }

    /// Fill each pixel with a new random color.
    @discardableResult
    public func randomBackground(alpha: Double = 1) -> BitmapCanvas {
        for x in 0 ..< context.width {
            for y in 0 ..< context.height {
                let color = Color(.random(in: 0...1), .random(in: 0...1), .random(in: 0...1))
                fill(Pixel(x, y), with: color, alpha: alpha)
            }
        }
        return self
    }

    /// Fill a single pixel with the given color.
    @discardableResult
    public func fill(_ pixel: Pixel, with color: Color, alpha: Double = 1, width: CGFloat = 1) -> BitmapCanvas {
        context.setFillColor(color.CGColor(withAlpha: alpha))
        context.translateBy(x: 0.5, y: 0.5) // Pixel <-> CGPoint conversion
        context.fill(CGRect(x: CGFloat(pixel.x) - width / 2, y: CGFloat(pixel.y) - width / 2, width: width, height: width))
        context.translateBy(x: -0.5, y: -0.5)
        return self
    }

    /// Fill a sequence of pixels with the given color.
    /// For example, you can stroke a PixelPath. Attention: When using this on a PixelPath, the path is getting exhausted, so this operation is NOT side-effect-free!
    @discardableResult
    public func fillPixels<S: Sequence>(_ pixels: S, with color: Color, alpha: Double = 1, width: CGFloat = 1) -> BitmapCanvas where S.Element == Pixel {
        pixels.reduce(self) { (_, pixel) in
            fill(pixel, with: color, alpha: alpha, width: width)
        }
    }

    // MARK: Write to File
    /// Write the current canvas content to a file.
    public func write(to file: String) {
        CGImage.write(to: file)
    }

    /// Write the current canvas content to the users desktop.
    public func writeToDesktop(name: String) {
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        write(to: desktop +/ name)
    }

    // MARK: Get CGImage
    /// Get the current CGImage representation of the canvas.
    public var CGImage: CGImage {
        context.makeImage()!
    }
}
