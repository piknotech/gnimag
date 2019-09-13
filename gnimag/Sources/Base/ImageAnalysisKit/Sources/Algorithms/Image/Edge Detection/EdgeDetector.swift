//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// EdgeDetector detects the edge of a shape which has a uniform color.
/// A starting point that is already at the edge is required.
/// Where the image bounds are hit, the edge continues outside the bounds, unless inverse is true.
public enum EdgeDetector {
    public enum DetectionLimit {
        case maxPixelsOnEdge(Int)
        case distance(to: Pixel, maximum: Double)
        case none
    }

    /// NOTE: If inverse = true, outside the bounds will count as belonging to the shape. Use it when detecting a shape from outside, i.e. when detecting the "inverse" shape.
    public static func search(
        in image: Image,
        shapeColor: ColorMatch,
        from startingPixel: Pixel,
        limit: DetectionLimit = .none,
        inverse: Bool = false,
        angle: CGFloat,
        searchSpeed: Int = 1
    ) -> [Pixel]? {
        guard let (inside, outside) = findPointOnTheEdge(image: image, shapeColor: shapeColor, from: startingPixel, inverse: inverse, angle: angle) else {
            return nil
        }

        let traverser = createTraverserFromStartingPoints(points: (inside, outside), image: image, shapeColor: shapeColor, inverse: inverse, speed: searchSpeed)

        return traverser.findEdge(limit: limit)
    }

    /// Walk (using angle) until hitting a pixel that has NOT the required shape color (or hitting the image wall). Then we have found the beginning of the edge.
    /// Return (point inside the shape, point outside the shape), or nil if it was not found.
    private static func findPointOnTheEdge(image: Image, shapeColor: ColorMatch, from pixel: Pixel, inverse: Bool, angle: CGFloat) -> (inside: Pixel, outside: Pixel)? {
        precondition(shapeColor.matches(image.color(at: pixel)), "The starting pixel (\(pixel)) must be inside the shape!")

        let extendedBounds = image.bounds.inset(by: (-1, -1))
        let path = StraightPath(start: pixel, angle: angle, bounds: extendedBounds) // This is done exactly (speed 1)

        var lastPixel = pixel
        
        // Walk loop
        while let pixel = path.next() {
            // Outside bounds: either inside or outside shape, depending on `inverse`
            if !image.contains(pixel) {
                if inverse { return nil }
                return (lastPixel, pixel)
            }

            // Inside bounds: check if outside shape
            if !shapeColor.matches(image.color(at: pixel)) {
                return (lastPixel, pixel)
            }
            
            lastPixel = pixel
        }

        // Before the path ends, it returned a pixel outside bounds --> the method has definitely returned already
        preconditionFailure()
    }

    /// Check if the found starting points are either adjacent horizontally or vertically; else (diagonally), change the starting points.
    /// Return the EdgeTraverser that can now be used to traverse the edge.
    private static func createTraverserFromStartingPoints(points: (inside: Pixel, outside: Pixel), image: Image, shapeColor: ColorMatch, inverse: Bool, speed: Int) -> EdgeTraverser {
        let delta = points.outside - points.inside

        // Choose matching rotation
        let rotation: Rotation?
        switch (delta.dx, delta.dy) {
        case let (x, y) where x == 0 && y > 0: // Outside is below inside
            rotation = .down
        case let (x, y) where x == 0 && y < 0: // Outside is above inside
            rotation = .up
        case let (x, y) where x > 0 && y == 0: // Outside is right of inside
            rotation = .right
        case let (x, y) where x < 0 && y == 0: // Outside is left of inside
            rotation = .left
        default:
            rotation = nil // Diagonally adjacent
        }

        if let rotation = rotation {
            return EdgeTraverser(initialPixel: points.inside, initialRotation: rotation, image: image, speed: speed, color: shapeColor, inverse: inverse)
        }

        // Else: |x| = |y|, diagonally adjacent

        // Get a point that is directly adjacent to both points
        let third = Pixel(points.inside.x, points.outside.y)
        let newPoints: (Pixel, Pixel)

        // Either use (third, outside) or (inside, third), depending on whether third is inside the shape or not
        if image.contains(third) && shapeColor.matches(image.color(at: third)) {
            newPoints = (third, points.outside)
        } else {
            newPoints = (points.inside, third)
        }

        return createTraverserFromStartingPoints(points: newPoints, image: image, shapeColor: shapeColor, inverse: inverse, speed: speed)
    }
}
