//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit

/// ImageAnalyzer extracts term strings from images.
class ImageAnalyzer {
    /// States whether the ImageAnalyzer has been initialized by `initializeWithFirstImage`.
    var isInitialized = false

    private var screen: ScreenLayout!
    private var coloring: Coloring!

    /// The OCR instance.
    private lazy var ocr = BitmapOCR(location: NSHomeDirectory() +/ "Library/Application Support/gnimag/identiti/OCR")

    /// Coloring describes color properties of the game.
    struct Coloring {
        let textColor = Color.white
        
        /// The central color of the background gradient.
        let background: Color

        /// The color of buttons and boxes.
        let foreground: Color
    }

    /// Initialize the ImageAnalyzer by detecting the ScreenLayout using the first image.
    /// This does not yet analyze the first image; therefore, call `analyze(image:)`.
    /// Returns false if the screen layout couldn't be detected.
    func initializeWithFirstImage(_ image: Image) -> Bool {
        precondition(!isInitialized)

        // Find background color
        let background = backgroundColor(of: image)
        let backgroundMatch = ColorMatch.color(background, tolerance: 0.1)

        // Find buttons
        guard let buttons = findButtons(in: image, background: backgroundMatch) else { return false }

        // Use "=" button to detect foreground color ("=" sign is transparent in the middle)
        let foreground = image.color(at: buttons.right.center.nearestPixel)
        let foregroundMatch = ColorMatch.color(foreground, tolerance: 0.05)

        // Find term boxes
        guard let boxes = findTermBoxes(in: image, with: buttons.left, foreground: foregroundMatch, background: backgroundMatch) else { return false }

        // Finalize
        coloring = Coloring(background: background, foreground: foreground)
        screen = ScreenLayout(
            upperTermBox: boxes.upper,
            lowerTermBox: boxes.lower,
            equalButton: buttons.right,
            notEqualButton: buttons.left
        )
        isInitialized = true

        return true
    }

    /// Analyze an image; return the exercise.
    /// Returns nil if there are no terms found in the image.
    func analyze(image: Image) -> Exercise? {
        guard let upperImage = content(of: screen.upperTermBox, in: image),
            let lowerImage = content(of: screen.lowerTermBox, in: image) else { return nil }

        // Perform OCR
        let textColor = coloring.textColor.withTolerance(0.2)
        guard let upperTerm = ocr.recognize(image: upperImage, textColor: textColor),
            let lowerTerm = ocr.recognize(image: lowerImage, textColor: textColor) else { return nil }

        return Exercise(
            upperTerm: upperTerm.joined(),
            lowerTerm: lowerTerm.joined()
        )
    }

    /// Check whether the specified box is fully on-screen and, if this is the case, return an image containing the box's content.
    private func content(of box: AABB, in image: Image) -> Image? {
        let foreground = ColorMatch.color(coloring.foreground, tolerance: 0.05)

        // Check for two starting pixels whether they are contained in the box.
        // This allows to detect the box while it is still animating and not yet on its exact final position.
        let pixels = [
            CGPoint(x: box.rect.minX, y: box.rect.minY).nearestPixel,
            CGPoint(x: box.rect.maxX, y: box.rect.minY).nearestPixel
        ]

        for pixel in pixels {
            guard foreground.matches(image.color(at: pixel)) else { continue }
            guard let edge = EdgeDetector.search(in: image, shapeColor: foreground, from: pixel, angle: .south, limit: .maxPixels(Int(2.5 * (box.width + box.height)))) else { continue }

            var aabb = SmallestAABB.containing(edge)
            removeCorners(from: &aabb, foreground: foreground, in: image)

            // Check if detected box is valid; then, crop image to this box
            // (Corner removal can yield somewhat varying results -> high tolerance for width)
            if aabb.width.isAlmostEqual(to: box.width, tolerance: 15) &&
                aabb.height.isAlmostEqual(to: box.height, tolerance: 2) {
                return image.cropped(to: Bounds(rect: aabb.rect))
            }
        }

        return nil
    }

    // MARK: Helper Methods for Initialization

    /// The central color of the background gradient.
    private func backgroundColor(of image: Image) -> Color {
        let center = Pixel(5, image.height / 2)
        return image.color(at: center)
    }

    /// Find the locations of the true and false buttons.
    private func findButtons(in image: Image, background: ColorMatch) -> (left: Circle, right: Circle)? {
        let inset = 5 // Remove possible edge artifacts

        // Left button
        let leftPath = StraightPath(start: Pixel(inset, inset), angle: .northeast, bounds: image.bounds)
        guard let leftPixel = image.findFirstPixel(matching: !background, on: leftPath),
            let leftEdge = EdgeDetector.search(in: image, shapeColor: !background, from: leftPixel, angle: .north) else { return nil }
        let leftCircle = SmallestCircle.containing(leftEdge)

        // Right button
        let rightPath = StraightPath(start: Pixel(image.width - 1 - inset, inset), angle: .northwest, bounds: image.bounds)
        guard let rightPixel = image.findFirstPixel(matching: !background, on: rightPath),
            let rightEdge = EdgeDetector.search(in: image, shapeColor: !background, from: rightPixel, angle: .north) else { return nil }
        let rightCircle = SmallestCircle.containing(rightEdge)

        // Validate layout
        guard leftCircle.radius.isAlmostEqual(to: rightCircle.radius, tolerance: 2),
            leftCircle.center.y.isAlmostEqual(to: rightCircle.center.y, tolerance: 2) else { return nil }

        return (left: leftCircle, right: rightCircle)
    }

    /// Find the locations of the term boxes.
    /// The AABBs are cut in such a way that the rounded corners are removed, i.e. that anything inside the AABBs has foreground color.
    private func findTermBoxes(in image: Image, with leftButton: Circle, foreground: ColorMatch, background: ColorMatch) -> (upper: AABB, lower: AABB)? {
        // Use the upper-left corner from the left button to start walking upwards
        let point = leftButton.point(at: 0.75 * .pi).nearestPixel + Delta(-3, 3)
        let path = StraightPath(start: point, angle: .north, bounds: image.bounds)

        // Find pixels inside lower and upper box
        guard let insideLowerBox = image.findFirstPixel(matching: foreground, on: path) else { return nil }
        _ = image.findLastPixel(matching: foreground, on: path) // Move outside lower box
        guard let insideUpperBox = image.findFirstPixel(matching: foreground, on: path) else { return nil }

        // Find bounding boxes
        guard let lowerEdge = EdgeDetector.search(in: image, shapeColor: foreground, from: insideLowerBox, angle: .north),
            let upperEdge = EdgeDetector.search(in: image, shapeColor: foreground, from: insideUpperBox, angle: .north) else { return nil }

        var lowerAABB = SmallestAABB.containing(lowerEdge)
        removeCorners(from: &lowerAABB, foreground: foreground, in: image)

        var upperAABB = SmallestAABB.containing(upperEdge)
        removeCorners(from: &upperAABB, foreground: foreground, in: image)

        // Validate layout
        guard lowerAABB.width.isAlmostEqual(to: upperAABB.width, tolerance: 3),
            lowerAABB.height.isAlmostEqual(to: upperAABB.height, tolerance: 3),
            lowerAABB.center.x.isAlmostEqual(to: upperAABB.center.x, tolerance: 2) else { return nil }

        return (upper: upperAABB, lower: lowerAABB)
    }

    /// Cut an AABB in such a way that the rounded corners are removed, i.e. that anything inside the AABBs has foreground color.
    private func removeCorners(from aabb: inout AABB, foreground: ColorMatch, in image: Image) {
        let lowerLeft = aabb.rect.origin.nearestPixel
        let path = StraightPath(start: lowerLeft, angle: .northeast, bounds: image.bounds)
        guard let inside = image.findFirstPixel(matching: foreground, on: path) else { return }

        let distance = CGFloat(inside.distance(to: lowerLeft))
        aabb = aabb.inset(by: (distance, distance))
        aabb = aabb.inset(by: (2, 2)) // Additional safety inset
    }
}
