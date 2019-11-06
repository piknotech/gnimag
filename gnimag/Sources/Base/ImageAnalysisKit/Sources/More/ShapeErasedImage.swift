//
//  Created by David Knothe on 24.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Image
import MacTestingTools

/// An image that consists of another image, but has one or multiple shapes erased with a given color.
public final class ShapeErasedImage: Image {
    /// The original image.
    @usableFromInline
    let image: Image

    /// The shapes and the color with which the shapes will be erased from the image.
    @usableFromInline
    let shapes: [ShapeErasureType]

    @usableFromInline
    let color: Color

    /// Default initializer.
    public init(image: Image, shapes: [ShapeErasureType], color: Color = .erase) {
        self.image = image
        self.shapes = shapes
        self.color = color

        super.init(width: image.width, height: image.height)
    }

    /// Convenience initializer, just using one shape.
    public convenience init(image: Image, shape: ShapeErasureType, color: Color = .erase) {
        self.init(image: image, shapes: [shape], color: color)
    }

    /// Return the color of the original image, or return the erased color iff the pixel is inside the shape.
    @inlinable @inline(__always)
    override public func color(at pixel: Pixel) -> Color {
        if (shapes.any { $0.contains(pixel) }) {
            return color
        } else {
            return image.color(at: pixel)
        }
    }
}

public extension Color {
    /// A color which will not match any other normal color (given that tolerance is in [0,1]).
    /// When being drawn (e.g. with BitmapCanvas), this color will be drawn as a black-white checkerboard pattern.
    static let erase = Color(-999, -999, -999)
}

/// ShapeErasedImage is ConvertibleToCGImage iff the original image is also ConvertibleToCGImage.
extension ShapeErasedImage: ConvertibleToCGImage {
    public var CGImage: CGImage {
        let canvas = BitmapCanvas(image: image)

        for shape in shapes {
            draw(shape: shape, onto: canvas, with: color, imageBounds: bounds)
        }

        return canvas.CGImage
    }

    /// Draw the given shape onto the BitmapCanvas, pixel by pixel.
    private func draw(shape: ShapeErasureType, onto canvas: BitmapCanvas, with color: Color, imageBounds: Bounds) {
        let aabb = shape.boundingBox(withImageBounds: imageBounds)

        // Fill each pixel inside the shape manually – using BitmapCanvas to fill the shape would be faster, but would not exactly represent the image with respect to `color(at:)`.
        for x in Int(floor(aabb.rect.minX)) ... Int(ceil(aabb.rect.maxX)) {
            for y in Int(floor(aabb.rect.minY)) ... Int(ceil(aabb.rect.maxY)) {
                let pixel = Pixel(x, y)
                if shape.contains(pixel) {
                    // Special handling for Color.erase: instead of black, use a black-white checkerboard pattern
                    if color == .erase {
                        let color = (x + y).isMultiple(of: 2) ? Color.white : .black
                        canvas.fill(pixel, with: color)
                    } else {
                        canvas.fill(pixel, with: color)
                    }
                }
            }
        }
    }
}
