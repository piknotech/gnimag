//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Image

/// EdgeTraverser holds the context of a microscopic edge checking operation, always involving one pixel inside and one pixel outside the shape.
/// Depending on the color of the surrounding pixels, the context is moved, rotated, etc. to gain the next meaningful context that can be checked. This is done in a counter-clockwise manner.
internal class EdgeTraverser {
    /// The current pixel which is inside the shape (= on the edge).
    /// The pixel above this pixel (considering the context's rotation and speed) is always outside the shape.
    private(set) var currentPixel: Pixel
    
    /// The current rotation of the context.
    private var rotation: Rotation

    private let image: Image
    private let speed: Int
    private let color: ColorMatch
    private let outsideBoundsIsInsideShape: Bool

    /// Default initializer.
    init(initialPixel: Pixel, initialRotation: Rotation, image: Image, speed: Int, color: ColorMatch, inverse: Bool) {
        self.currentPixel = initialPixel
        self.rotation = initialRotation
        self.image = image
        self.speed = speed
        self.color = color
        self.outsideBoundsIsInsideShape = inverse
    }

    /// Find the edge using this EdgeTraverser.
    /// Perform iterations until eiter hitting the starting pixel again or hitting the limit.
    func findEdge(limit: EdgeDetector.DetectionLimit) -> [Pixel]? {
        let startingPixel = currentPixel
        var edge = [startingPixel]

        // Iterate until hitting starting point again
        while true {
            iterate()

            // Check limit
            switch limit {
            case let .maxPixels(maxPixels):
                if edge.count > maxPixels { return nil }

            case let .distance(to: pixel, maximum: maximum):
                if pixel.distance(to: pixel) > maximum { return nil }

            case .none:
                ()
            }

            // Possibly stop if starting point was reached
            if currentPixel == startingPixel {
                // Test if the next pixel is already in the edge; if not, continue
                let last = currentPixel
                iterate()
                if edge.contains(currentPixel) { return edge } // Pixel already in the edge, stop
                edge.append(last)
            }

            edge.append(currentPixel)
        }
    }
    
    /// Perform a context checking iteration.
    /// The edge will be continued in a matching direction with a single pixel.
    /// The context will be modified, the new pixel (self.pixel) can be added, and the next checking iteration can be performed.
    private func iterate() {
        // Calculate the four checking pixels
        let left =      Delta(-1, 0).rotated(by: rotation).scaled(by: speed)
        let upLeft =    Delta(-1, -1).rotated(by: rotation).scaled(by: speed)
        let down =      Delta(0, 1).rotated(by: rotation).scaled(by: speed)
        let downLeft =  Delta(-1, 1).rotated(by: rotation).scaled(by: speed)
        
        let check1 = currentPixel + left
        let check2 = currentPixel + upLeft
        let check3 = currentPixel + down
        let check4 = currentPixel + downLeft
        
        // Helper method
        func isInsideShape(_ pixel: Pixel) -> Bool {
            return image.contains(pixel) && color.matches(image.color(at: pixel))
        }
        
        // Check 1
        if isInsideShape(check1) {
            // Check 2
            if isInsideShape(check2) {
                currentPixel = check2
                rotation = rotation.rotated(by: .right) // Turn 90° right
            }
            else {
                currentPixel = check1 // Maintain rotation
            }
        }
        else {
            // Check 3
            if isInsideShape(check3) {
                // Check 4
                if isInsideShape(check4) {
                    currentPixel = check4 // Maintain rotation
                }
                else {
                    currentPixel = check3
                    rotation = rotation.rotated(by: .left) // Turn 90° left
                }
            }
            else {
                rotation = rotation.rotated(by: .down) // Turn 180°
            }
        }
    }
}
