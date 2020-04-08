//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit

/// Height of the ad at the bottom. Varies depending on device / OS.
private let adHeight = 100

/// ImageAnalyzer extracts term strings from images.
class ImageAnalyzer {
    /// States whether the ImageAnalyzer has been initialized by `initializeWithFirstImage`.
    var isInitialized = false

    /// The OCR instance.
    private let ocr: BitmapOCR

    private(set) var screen: ScreenLayout!
    private var coloring: Coloring!

    /// Coloring describes color properties of the game.
    struct Coloring {
        let textColor = Color(0.9, 0.9, 0.9)
        
        /// The background gradient.
        let background: ColorMatch

        /// The color of buttons and boxes.
        let foreground: ColorMatch
        let foregroundColor: Color
    }

    /// Default initializer.
    init(os: identiti.OSType) {
        // Create OCR instance from the correct directory
        let baseLocation = NSHomeDirectory() +/ "Library/Application Support/gnimag/YesNoMathGames/identiti/OCR"
        switch os {
        case .iOS:
            ocr = BitmapOCR(location: baseLocation +/ "iOS", configFileDirectory: baseLocation)
        case .android:
            ocr = BitmapOCR(location: baseLocation +/ "Android", configFileDirectory: baseLocation)
        }
    }

    /// Initialize the ImageAnalyzer by detecting the ScreenLayout using the first image.
    /// This does not yet analyze the first image; therefore, call `analyze(image:)`.
    /// Returns false if the screen layout couldn't be detected.
    func initializeWithFirstImage(_ image: Image) -> Bool {
        precondition(!isInitialized)

        // Find background color gradient
        let background = backgroundColorGradient(of: image)

        // Find buttons
        guard let buttons = findButtons(in: image, background: background) else {
            Terminal.log(.error, "Buttons couldn't be found!")
            return false
        }

        // Use "=" button to detect foreground color ("=" sign is transparent in the middle)
        let foregroundColor = image.color(at: buttons.right.center.nearestPixel)
        let foreground = ColorMatch.color(foregroundColor, tolerance: 0.05)

        // Find term boxes
        guard let boxes = findTermBoxes(in: image, with: buttons.left, foreground: foreground, background: background) else {
            Terminal.log(.error, "Term boxes couldn't be found!")
            return false
        }

        // Finalize
        coloring = Coloring(background: background, foreground: foreground, foregroundColor: foregroundColor)
        screen = ScreenLayout(
            upperTermBox: boxes.upper,
            lowerTermBox: boxes.lower,
            equalButtonCenter: buttons.right.center,
            notEqualButtonCenter: buttons.left.center,
            size: CGSize(width: image.width, height: image.height)
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
            let lowerTerm = ocr.recognize(image: lowerImage, textColor: textColor) else {
            Terminal.log(.error, "Terms couldn't be recognized!")
            return nil
        }

        return Exercise(
            upperTerm: upperTerm.joined(),
            lowerTerm: lowerTerm.joined()
        )
    }

    /// Check whether the specified box is fully on-screen and, if this is the case, return an image containing the box's content.
    private func content(of box: AABB, in image: Image) -> Image? {
        // Check for some starting pixels whether they are contained in the box.
        // This allows to detect the box while it is still animating and not yet on its exact final position.
        let pixels = [
            CGPoint(x: box.rect.midX, y: box.rect.minY + 5).nearestPixel,
            CGPoint(x: box.rect.midX, y: box.rect.minY - 5).nearestPixel,
            CGPoint(x: box.rect.minX + 5, y: box.rect.midY).nearestPixel,
            CGPoint(x: box.rect.maxX - 5, y: box.rect.midY).nearestPixel
        ]

        for pixel in pixels {
            guard coloring.foreground.matches(image.color(at: pixel)) else { continue }
            guard let edge = EdgeDetector.search(in: image, shapeColor: coloring.foreground, from: pixel, angle: .south, limit: .maxPixels(Int(2.5 * (box.width + box.height)))) else { continue }

            var aabb = SmallestAABB.containing(edge)
            safetyInset(&aabb)

            // Check if detected box is valid; then, crop image to this box
            // (Corner removal can yield somewhat varying results -> high tolerance for width)
            if aabb.width.isAlmostEqual(to: box.width, tolerance: 15) &&
                aabb.height.isAlmostEqual(to: box.height, tolerance: 5) {
                let cropped = image.cropped(to: Bounds(rect: aabb.rect))
                return overlayCorners(of: cropped, with: coloring.foregroundColor)
            }
        }

        return nil
    }

    /// Remove the corners of an image. This is useful when there are artifacts in the corners that would distract image analysis (as it is the case on iOS).
    private func overlayCorners(of image: Image, with color: Color) -> Image {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: image.height - 1), CGPoint(x: image.width - 1, y: 0), CGPoint(x: image.width - 1, y: image.height - 1)]
        let shapes = points.map { point -> ShapeErasureType in // Erase all four corners
            .shape(OBB(center: point, width: 10, height: 10, rotation: .pi / 4))
        }
        return ShapeErasedImage(image: image, shapes: shapes)
    }

    // MARK: Helper Methods for Initialization

    /// The central color of the background gradient.
    private func backgroundColorGradient(of image: Image) -> ColorMatch {
        let lower = Pixel(5, adHeight)
        let upper = Pixel(5, image.height - 50)
        return .gradient(from: image.color(at: lower), to: image.color(at: upper), tolerance: 0.05)
    }

    /// Find the locations of the true and false buttons.
    private func findButtons(in image: Image, background: ColorMatch) -> (left: Circle, right: Circle)? {
        let inset = 5 // Remove possible edge artifacts

        // Left button
        let leftPath = StraightPath(start: Pixel(inset, inset + adHeight), angle: .northeast, bounds: image.bounds)
        guard let leftPixel = image.findFirstPixel(matching: !background, on: leftPath),
            let leftEdge = EdgeDetector.search(in: image, shapeColor: !background, from: leftPixel, angle: .north) else { return nil }
        let leftCircle = SmallestCircle.containing(leftEdge)

        // Right button
        let rightPath = StraightPath(start: Pixel(image.width - 1 - inset, inset + adHeight), angle: .northwest, bounds: image.bounds)
        guard let rightPixel = image.findFirstPixel(matching: !background, on: rightPath),
            let rightEdge = EdgeDetector.search(in: image, shapeColor: !background, from: rightPixel, angle: .north) else { return nil }
        let rightCircle = SmallestCircle.containing(rightEdge)

        // Validate layout
        guard leftCircle.radius.isAlmostEqual(to: rightCircle.radius, tolerance: 3),
            leftCircle.center.y.isAlmostEqual(to: rightCircle.center.y, tolerance: 3) else { return nil }

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
        safetyInset(&lowerAABB)

        var upperAABB = SmallestAABB.containing(upperEdge)
        safetyInset(&upperAABB)

        // Validate layout
        guard lowerAABB.width.isAlmostEqual(to: upperAABB.width, tolerance: 3),
            lowerAABB.height.isAlmostEqual(to: upperAABB.height, tolerance: 3),
            lowerAABB.center.x.isAlmostEqual(to: upperAABB.center.x, tolerance: 2) else { return nil }

        return (upper: upperAABB, lower: lowerAABB)
    }

    /// Minimally inset a term box AABB.
    private func safetyInset(_ aabb: inout AABB) {
        aabb = aabb.inset(by: (2, 2))
    }
}
