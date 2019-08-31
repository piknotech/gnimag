//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import ImageInput

/// EdgeDetector detects the edge of a shape which has a uniform color.
/// A starting point that is already at the edge is required.
/// Where the image bounds are hit, the edge continues outside the bounds.
/// TODO: Inverse edges are not yet supported.
public enum EdgeDetector {
    /// The starting pixel must match the shapeColor. angle is the angle that will be walked until finding a pixel outisde the shape. When inverse = true, outside bounds will count as matching shapeColor.
    public static func search(
        in image: Image,
        shapeColor: ColorMatch,
        from startingPixel: Pixel,
        angle: Double = 0,
        searchSpeed: Int = 1
    ) -> [Pixel] {
        guard let (inside, outside) = findPointOnTheEdge(image: image, shapeColor: shapeColor, from: startingPixel, angle: angle) else {
            return [] // Empty edge
        }
        
        // Create context, find edge
        var context = createTraverserFromStartingPoints(points: (inside, outside), image: image, shapeColor: shapeColor)
        let edge = findEdge(from: &context, image: image, shapeColor: shapeColor, searchSpeed: searchSpeed)
        
        return edge
    }

    /// Walk (using angle) until hitting a pixel that has NOT the required shape color (or hitting the image wall). Then we have found the beginning of the edge.
    /// Return (point inside the shape, point outside the shape), or nil if it was not found.
    private static func findPointOnTheEdge(image: Image, shapeColor: ColorMatch, from pixel: Pixel, angle: Double) -> (inside: Pixel, outside: Pixel)? {
        precondition(shapeColor.matches(image.color(at: pixel)), "The starting pixel (\(pixel)) must be inside the shape!")

        let extendedBounds = image.bounds.inset(by: (-1, -1))
        var path = StraightPath(start: pixel, angle: angle, bounds: extendedBounds) // This is done exactly (speed 1)

        var lastPixel = pixel
        
        // Walk loop
        while let pixel = path.next() {
            // Outside bounds: either inside or outside shape, depending on `inverse`
            if !image.contains(pixel) {
                /* if inverse { return nil } – TODO */
                return (lastPixel, pixel)
            }

            // Inside bounds: check if outside shape
            if !shapeColor.matches(image.color(at: pixel)) {
                return (lastPixel, pixel)
            }
            
            lastPixel = pixel
        }

        // Before the path ends, it returned a pixel outside bounds --> the method has definitely returned already
        fatalError()
    }

    /// Check if the found starting points are either adjacent horizontally or vertically; else (diagonally), change the starting points.
    /// If clockwise = true, swap the 
    /// Return the EdgeTraverser that can now be used to traverse the edge.
    private static func createTraverserFromStartingPoints(points: (inside: Pixel, outside: Pixel), image: Image, shapeColor: ColorMatch) -> EdgeTraverser {
        let delta = points.outside - points.inside

        // Check the alignment
        switch (delta.dx, delta.dy) {
        case let (x, y) where x == 0 && y > 0: // Outside is below inside
            return EdgeTraverser(pixel: points.inside, rotation: .down)
            
        case let (x, y) where x == 0 && y < 0: // Outside is above inside
            return EdgeTraverser(pixel: points.inside, rotation: .up)

        case let (x, y) where x > 0 && y == 0: // Outside is right of inside
            return EdgeTraverser(pixel: points.inside, rotation: .right)

        case let (x, y) where x < 0 && y == 0: // Outside is left of inside
            return EdgeTraverser(pixel: points.inside, rotation: .left)
            
        case let (x, y) where abs(x) == abs(y): // Diagonally
            // Get a point that is directly adjacent to both points
            let third = Pixel(points.inside.x, points.outside.y)
            
            if image.contains(third) && shapeColor.matches(image.color(at: third)) {
                // Inside the shape: use (third, outside)
                return createTraverserFromStartingPoints(points: (third, points.outside), image: image, shapeColor: shapeColor)
            } else {
                // Outside the shape: use (inside, third)
                return createTraverserFromStartingPoints(points: (points.inside, third), image: image, shapeColor: shapeColor)
            }
            
        default: // Impossible
            fatalError()
        }
    }
    
    /// STEP FOUR: Walk on context until hitting the starting point again, each time adding the new point to the edge.
    private static func findEdge(from context: inout EdgeTraverser, image: Image, shapeColor: ColorMatch, searchSpeed: Int) -> [Pixel] {
        let startingPixel = context.pixel
        var edge = [startingPixel]
        
        // Iterate until hitting starting point again
        while true {
            context.iterate(image: image, color: shapeColor, speed: searchSpeed)

            if context.pixel == startingPixel {
                return edge
            }
            
            edge.append(context.pixel)
        }
    }
}
