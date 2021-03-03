//
//  Created by David Knothe on 24.09.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Image

/// Possibilities for how to erase shapes for a ShapeErasedImage.
public enum ShapeErasureType {
    /// Erase the given shape.
    case shape(Shape)

    /// Erase the opposite of the shape.
    case anti(Shape)

    /// Calculate the AABB of the shape; for an anti-shape, the AABB is the whole image.
    /// This means, drawing an anti-shape (using BitmapCanvas) will be extremely slow.
    func boundingBox(withImageBounds bounds: Bounds) -> AABB {
        let boundsRect = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)

        switch self {
        case let .shape(shape): // Intersect with the image bounds to prevent drawing/reading outside the image
            return AABB(rect: shape.boundingBox.rect.intersection(boundsRect))

        case .anti:
            return AABB(rect: boundsRect)
        }
    }

    /// Check if the (anti-)shape contains the given pixel.
    @_transparent @usableFromInline
    func contains(_ pixel: Pixel) -> Bool {
        switch self {
        case let .shape(shape):
            return shape.contains(pixel.CGPoint)

        case let .anti(shape):
            return !shape.contains(pixel.CGPoint)
        }
    }
}
