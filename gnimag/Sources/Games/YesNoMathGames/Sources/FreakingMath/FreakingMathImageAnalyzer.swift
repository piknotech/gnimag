//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
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
            Terminal.log(.error, "Score text couldn't be found or isn't 0!")
            return nil
        }

        // Find buttons
        guard let buttons = findButtons(in: image, background: background) else {
            Terminal.log(.error, "Buttons couldn't be found!")
            return nil
        }

        // Find term boxes
        guard let boxes = findTermBoxes(in: image, lowerStart: buttons.left.rect.maxY + 20, upperStart: scoreTextAABB.rect.minY - 20) else {
            Terminal.log(.error, "Term boxes couldn't be found!")
            return nil
        }

        // Finalize
        screen = ScreenLayout(
            upperTermBox: boxes.upper,
            lowerTermBox: boxes.lower,
            equalButtonCenter: buttons.left.center,
            notEqualButtonCenter: buttons.right.center,
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
        let white = Color.white.withTolerance(0.1)

        // Find end of upper bar
        let corner = Pixel(image.width - 5, image.height - 1)
        let path = StraightPath(start: corner, angle: .south, bounds: image.bounds)
        let sequence = ColorMatchSequence([white, .not(white)])
        guard let barEnd = image.follow(path: path, untilFulfillingSequence: sequence).fulfilledPixel else { return nil }

        // Find start of "0"
        let diagonal = StraightPath(start: barEnd, angle: Angle(1.35 * .pi), bounds: image.bounds)
        guard let zero = image.findFirstPixel(matching: white, on: diagonal) else { return nil }

        // Guess AABB
        let length = barEnd.distance(to: zero)
        if length > 100 { return nil }
        let firstCorner = barEnd.CGPoint - CGPoint(x: 2, y: 2)
        let otherCorner = barEnd.CGPoint - CGPoint(x: 4 * length, y: 2.5 * length)
        let aabb = AABB(containing: [firstCorner, otherCorner])

        // Verify text is "0"
        let scoreImage = content(of: aabb, in: image)
        guard ocr.recognize(image: scoreImage, textColor: Coloring.textColor) == ["0"] else {
            return nil
        }
        
        return aabb
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
        guard leftAABB.width.isAlmostEqual(to: rightAABB.width, tolerance: 3),
            leftAABB.height.isAlmostEqual(to: rightAABB.height, tolerance: 3),
            leftAABB.center.y.isAlmostEqual(to: rightAABB.center.y, tolerance: 3) else { return nil }

        return (left: leftAABB, right: rightAABB)
    }

    /// Find the locations of the term boxes.
    private func findTermBoxes(in image: Image, lowerStart: CGFloat, upperStart: CGFloat) -> (upper: AABB, lower: AABB)? {
        // Lower edge
        let lowerSegment = LineSegment(from: CGPoint(x: 0.25 * CGFloat(image.width), y: lowerStart), to: CGPoint(x: 0.75 * CGFloat(image.width), y: lowerStart))
        let lowerPath = MovingLineSegmentPath(
            initialLineSegment: lowerSegment, numOfLineSegments: 200, movementAngle: .north, movementSpeed: 2, randomness: 0.5, numberOfPointsPerLineSegment: 50, bounds: image.bounds)
        guard let lower = image.findFirstPixel(matching: Coloring.textColor, on: lowerPath) else { return nil }

        // Upper edge
        let upperSegment = LineSegment(from: CGPoint(x: 0.25 * CGFloat(image.width), y: upperStart), to: CGPoint(x: 0.75 * CGFloat(image.width), y: upperStart))
        let upperPath = MovingLineSegmentPath(
            initialLineSegment: upperSegment, numOfLineSegments: 200, movementAngle: .south, movementSpeed: 2, randomness: 0.5, numberOfPointsPerLineSegment: 50, bounds: image.bounds)
        guard let upper = image.findFirstPixel(matching: Coloring.textColor, on: upperPath) else { return nil }

        // Create boxes
        let lowerY = (lower.y + Int(lowerStart)) / 2
        let upperY = (upper.y + Int(upperStart)) / 2
        let middleY = (lower.y + upper.y) / 2

        let inset = 5
        let lowerBox = AABB(containing: [CGPoint(x: inset, y: lowerY), CGPoint(x: image.width - inset, y: middleY)])
        let upperBox = AABB(containing: [CGPoint(x: inset, y: upperY), CGPoint(x: image.width - inset, y: middleY)])

        return (upper: upperBox, lower: lowerBox)
    }
}
