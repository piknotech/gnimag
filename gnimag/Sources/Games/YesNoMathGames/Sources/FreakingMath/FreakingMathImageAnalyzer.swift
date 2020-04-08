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
class FreakingMathImageAnalyzer: ImageAnalyzerProtocol {
    /// States whether the ImageAnalyzer has been initialized by `initializeWithFirstImage`.
    var isInitialized = false
    private var screen: ScreenLayout!

    /// The aabb of the score text label.
    private var scoreTextAABB: AABB!

    /// Coloring describes color properties of the game.
    struct Coloring {
        static let textColor = Color.white.withTolerance(0.1)
    }

    /// The OCR instance.
    private let ocr: BitmapOCR

    /// Default initializer.
    init(game: FreakingMath.Game) {
        // Create OCR instance from the correct directory
        let baseLocation = NSHomeDirectory() +/ "Library/Application Support/gnimag/YesNoMathGames/FreakingMath/OCR"
        switch game {
        case .normal:
            ocr = BitmapOCR(location: baseLocation +/ "normal", configFileDirectory: baseLocation)
        case .plus:
            ocr = BitmapOCR(location: baseLocation +/ "+", configFileDirectory: baseLocation)
        }
    }

    /// Initialize the ImageAnalyzer by detecting the ScreenLayout using the first image.
    /// Returns nil if the screen layout couldn't be detected.
    func initializeWithFirstImage(_ image: Image) -> ScreenLayout? {
        precondition(!isInitialized)

        // Find background color
        let background = backgroundColor(of: image)

        // Find score text AABB
        scoreTextAABB = findScoreTextAABB(in: image)
        if scoreTextAABB == nil {
            Terminal.log(.error, "Score text couldn't be found!")
            return nil
        }

        // Find buttons
        guard let buttons = findButtons(in: image, background: background) else {
            Terminal.log(.error, "Buttons couldn't be found!")
            return nil
        }

        // Find term boxes
        guard let boxes = findTermBoxes(in: image, with: buttons.left, background: background) else {
            Terminal.log(.error, "Term boxes couldn't be found!")
            return nil
        }

        // Finalize
        screen = ScreenLayout(
            upperTermBox: boxes.upper,
            lowerTermBox: boxes.lower,
            equalButtonCenter: buttons.right.center,
            notEqualButtonCenter: buttons.left.center,
            size: CGSize(width: image.width, height: image.height)
        )
        isInitialized = true

        return screen
    }

    /// Analyze an image and return the exercise.
    /// Returns nil if no terms were found in the image.
    func analyze(image: Image) -> Exercise? {

        let upperImage = content(of: screen.upperTermBox, in: image)
        let lowerImage = content(of: screen.lowerTermBox, in: image)

        // Perform OCR
        guard let upperTerm = ocr.recognize(image: upperImage, textColor: Coloring.textColor),
            var lowerTerm = ocr.recognize(image: lowerImage, textColor: Coloring.textColor) else {
            Terminal.log(.error, "Terms couldn't be recognized!")
            return nil
        }

        // Remove leading `=` from lower term
        if lowerTerm.first == "=" {
            lowerTerm.removeFirst()
        }

        return Exercise(
            upperTerm: upperTerm.joined(),
            lowerTerm: lowerTerm.joined()
        )
    }

    /// Get the text of the score label.
    func scoreText(of image: Image) -> String? {
        let scoreImage = content(of: scoreTextAABB, in: image)

        if let score = ocr.recognize(image: scoreImage, textColor: Coloring.textColor)?.joined() {
            return score
        } else {
            Terminal.log(.error, "Score couldn't be read!")
            return nil
        }
    }

    /// Return an image containing the given rectangle's content.
    private func content(of aabb: AABB, in image: Image) -> Image {
        image.cropped(to: Bounds(rect: aabb.rect))
    }

    // MARK: Helper Methods for Initialization

    /// The background color match.
    private func backgroundColor(of image: Image) -> ColorMatch {
        let center = Pixel(5, image.height / 2)
        return image.color(at: center).withTolerance(0.05)
    }

    /// Guess the aabb of the score text.
    private func findScoreTextAABB(in image: Image) -> AABB? {
        nil
    }

    /// Find the locations of the true and false buttons.
    private func findButtons(in image: Image, background: ColorMatch) -> (left: AABB, right: AABB)? {
        let inset = 5 // Remove possible edge artifacts

        let buttonForeground = Color.white.withTolerance(0.15)
        let buttonMatch = ColorMatch.block { color in
            buttonForeground.matches(color) && !background.matches(color)
        }

        // Left button
        let leftPath = StraightPath(start: Pixel(inset, inset), angle: .northeast, bounds: image.bounds)
        guard let leftPixel = image.findFirstPixel(matching: buttonMatch, on: leftPath),
            let leftEdge = EdgeDetector.search(in: image, shapeColor: buttonMatch, from: leftPixel, angle: .north) else { return nil }
        let leftAABB = SmallestAABB.containing(leftEdge)

        // Right button
        let rightPath = StraightPath(start: Pixel(image.width - 1 - inset, inset), angle: .northwest, bounds: image.bounds)
        guard let rightPixel = image.findFirstPixel(matching: buttonMatch, on: rightPath),
            let rightEdge = EdgeDetector.search(in: image, shapeColor: buttonMatch, from: rightPixel, angle: .north) else { return nil }
        let rightAABB = SmallestAABB.containing(rightEdge)

        // Validate layout
        guard leftAABB.width.isAlmostEqual(to: leftAABB.height, tolerance: 3),
            leftAABB.width.isAlmostEqual(to: rightAABB.width, tolerance: 3),
            rightAABB.width.isAlmostEqual(to: rightAABB.height, tolerance: 3),
            leftAABB.center.y.isAlmostEqual(to: rightAABB.center.y, tolerance: 3) else { return nil }

        return (left: leftAABB, right: rightAABB)
    }

    /// Find the locations of the term boxes.
    private func findTermBoxes(in image: Image, with leftButton: AABB, background: ColorMatch) -> (upper: AABB, lower: AABB)? {
        nil
    }
}
