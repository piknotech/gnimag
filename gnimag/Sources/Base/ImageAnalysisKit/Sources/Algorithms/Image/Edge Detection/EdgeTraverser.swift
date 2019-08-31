//
//  Created by David Knothe on 31.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import ImageInput

/// EdgeTraverser holds the context of a microscopic edge checking operation, always involving one pixel inside and one pixel outside the shape.
/// Depending on the color of the surrounding pixels, the context is moved, rotated, etc. to gain the next meaningful context that can be checked. This is done in a counter-clockwise manner.
internal struct EdgeTraverser {
    /// The current pixel which is inside the shape (= on the edge).
    /// The pixel above this pixel (considering the context's rotation and speed) is always outside the shape.
    private(set) var pixel: Pixel
    
    /// The current rotation of the context.
    private var rotation: Rotation

    /// Default initializer.
    init(pixel: Pixel, rotation: Rotation) {
        self.pixel = pixel
        self.rotation = rotation
    }
    
    /// Perform a context checking iteration.
    /// The edge will be continued in a matching direction with a single pixel.
    /// The context will be modified, the new pixel (self.pixel) can be added, and the next checking iteration can be performed.
    /// TODO: faster when image, color & speed are properties of EdgeTraverser?
    mutating func iterate(image: Image, color: ColorMatch, speed: Int) {
        // Calculate the four checking pixels
        let left =      Delta(-1, 0).rotated(by: rotation).scaled(by: speed)
        let upLeft =    Delta(-1, -1).rotated(by: rotation).scaled(by: speed)
        let down =      Delta(0, 1).rotated(by: rotation).scaled(by: speed)
        let downLeft =  Delta(-1, 1).rotated(by: rotation).scaled(by: speed)
        
        let check1 = pixel + left
        let check2 = pixel + upLeft
        let check3 = pixel + down
        let check4 = pixel + downLeft
        
        // Helper method
        func isInsideShape(_ pixel: Pixel) -> Bool {
            return image.contains(pixel) && color.matches(image.color(at: pixel))
        }
        
        // Check 1
        if isInsideShape(check1) {
            // Check 2
            if isInsideShape(check2) {
                pixel = check2
                rotation = rotation.rotated(by: .right) // Turn 90° right
            }
            else {
                pixel = check1 // Maintain rotation
            }
        }
        else {
            // Check 3
            if isInsideShape(check3) {
                // Check 4
                if isInsideShape(check4) {
                    pixel = check4 // Maintain rotation
                }
                else {
                    pixel = check3
                    rotation = rotation.rotated(by: .left) // Turn 90° left
                }
            }
            else {
                rotation = rotation.rotated(by: .down) // Turn 180°
            }
        }
    }
}
