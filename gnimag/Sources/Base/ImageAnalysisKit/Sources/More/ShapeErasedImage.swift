//
//  Created by David Knothe on 24.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Geometry
import Image
import MacTestingTools

/// An image that consists of another image, but has a specific shape erased with a given color.
public final class ShapeErasedImage: Image {
    /// The original image.
    private let image: Image

    /// The shape and the color with which the shape will be erased from the image.
    private let shape: Shape
    private let color: Color

    /// Default initializer.
    public init(image: Image, shape: Shape, color: Color) {
        self.image = image
        self.shape = shape
        self.color = color

        super.init(width: image.width, height: image.height)
    }

    /// Return the color of the original image, or return the erased color iff the pixel is inside the shape.
    override public func color(at pixel: Pixel) -> Color {
        if shape.contains(pixel.CGPoint) {
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
        let aabb = shape.boundingBox

        // Fill each pixel inside the shape manually – using BitmapCanvas to fill the shape would be faster, but would not exactly represent the image with respect to `color(at:)`.
        for x in Int(floor(aabb.rect.minX)) ... Int(ceil(aabb.rect.maxX)) {
            for y in Int(floor(aabb.rect.minY)) ... Int(ceil(aabb.rect.maxY)) {
                let pixel = Pixel(x, y)
                if shape.contains(pixel.CGPoint) {
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

        return canvas.CGImage
    }
}
