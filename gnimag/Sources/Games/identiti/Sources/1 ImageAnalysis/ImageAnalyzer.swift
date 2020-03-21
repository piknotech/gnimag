//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit

import TestingTools

/// ImageAnalyzer extracts equation strings from images.
class ImageAnalyzer {
    /// States whether the ImageAnalyzer has been initialized by `initializeWithFirstImage`.
    var isInitialized = false

    private var screen: ScreenLayout!
    private var coloring: Coloring!

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
        let image = image.inset(by: (5, 5)) // Remove possible edge artifacts
        
        // Find background color
        let background = backgroundColor(of: image)

        // Find buttons
        guard let buttons = findButtons(in: image, background: .color(background, tolerance: 0.1)) else { return false }

        // "=" sign is transparent in the middle -> use "=" button to detect foreground color
        let foreground = image.color(at: buttons.right.center.nearestPixel)

        // Find equation boxes
        guard let boxes = findEquationBoxes(in: image, foreground: .color(foreground, tolerance: 0.1)) else { return false }

        // Finalize
        coloring = Coloring(background: background, foreground: foreground)
        screen = ScreenLayout(
            upperEquationBox: boxes.upper,
            lowerEquationBox: boxes.lower,
            trueButton: buttons.right,
            falseButton: buttons.left
        )
        isInitialized = true

        return true
    }

    /// Analyze an image; return the exercise.
    /// Returns nil if there are no equations found on the image.
    func analyze(image: Image) -> RawExercise? {
        nil
    }

    // MARK: Helper Methods for Initialization

    /// The central color of the background gradient.
    private func backgroundColor(of image: Image) -> Color {
        let center = Pixel(5, image.height / 2)
        return image.color(at: center)
    }

    /// Find the locations of the true and false buttons.
    private func findButtons(in image: Image, background: ColorMatch) -> (left: Circle, right: Circle)? {
        // Left button
        let leftPath = StraightPath(start: Pixel(5, 5), angle: 0.25 * .pi, bounds: image.bounds)
        guard let leftPixel = image.findFirstPixel(matching: !background, on: leftPath),
            let leftEdge = EdgeDetector.search(in: image, shapeColor: !background, from: leftPixel, angle: .pi / 2) else { return nil }
        let leftCircle = SmallestCircle.containing(leftEdge.map(CGPoint.init))

        // Right button
        let rightPath = StraightPath(start: Pixel(image.width - 5, 5), angle: 0.75 * .pi, bounds: image.bounds)
        guard let rightPixel = image.findFirstPixel(matching: !background, on: rightPath),
            let rightEdge = EdgeDetector.search(in: image, shapeColor: !background, from: rightPixel, angle: .pi / 2) else { return nil }
        let rightCircle = SmallestCircle.containing(rightEdge.map(CGPoint.init))

        // Validate circle layout
        guard leftCircle.radius.isAlmostEqual(to: rightCircle.radius, tolerance: 2),
            leftCircle.center.y.isAlmostEqual(to: rightCircle.center.y, tolerance: 2) else { return nil }

        return (left: leftCircle, right: rightCircle)
    }

    /// Find the locations of the equation boxes.
    /// The AABBs are cut (left and right) in such a way that the rounded corners are removed, i.e. that anything inside the AABBs has either text color or foreground color, but not background color.
    private func findEquationBoxes(in image: Image, foreground: ColorMatch) -> (upper: AABB, lower: AABB)? {
        return nil
    }
}
