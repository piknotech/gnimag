//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit

/// ImageAnalyzer extracts levels from images.
class ImageAnalyzer {
    /// States whether the ImageAnalyzer has been initialized by `initializeWithFirstImage`.
    var isInitialized = false
    
    /// The ScreenLayout which is available after the first successful `analyze` call.
    private(set) var screen: ScreenLayout!

    /// Initialize the ImageAnalyzer by detecting the ScreenLayout (including the board) using the first image.
    /// This does not yet analyze the first image; therefore, call `analyze(image:)`.
    /// Returns false if the screen layout couldn't be detected.
    func initialize(with image: Image) -> Bool {
        precondition(!isInitialized)

        // Simply find the board; it will not change throughout the game
        guard let board = findBoard(in: image) else { return false }

        screen = ScreenLayout(board: board, size: CGSize(width: image.width, height: image.height))
        isInitialized = true

        return true
    }

    /// Analyze an image; return the level.
    /// Returns nil if no board or valid level is found in the image.
    func analyze(image: Image) -> Level? {
        if !validateBoard(in: image) { return nil }
        return findLevel(in: image)
    }

    /// Check whether the given image contains a valid board, i.e. the board is at the correct position.
    private func validateBoard(in image: Image) -> Bool {
        guard let board = findBoard(in: image) else { return false }

        if board.size != screen.board.size { return false }
        if board.aabb.center.distance(to: screen.board.aabb.center) > 5 { return false }
        if !board.aabb.width.isAlmostEqual(to: screen.board.aabb.width, tolerance: 3) { return false }
        return true
    }

    /// Find the level in an image using the existing board layout.
    private func findLevel(in image: Image) -> Level? {
        let elements = ((0 ..< screen.board.size) × (0 ..< screen.board.size)).map { (x, y) -> PositionAndColor in
            let position = Position(x, y)
            let center = screen.board.center(ofCellAt: position).nearestPixel
            return PositionAndColor(position: position, color: image.color(at: center))
        }

        let result = SimpleClustering.from(elements, maxDistance: 0.1)
        let clusters = result.clusters.sorted { $0.size < $1.size }

        // Check cluster validity: all clusters (except the background color) must have 2 elements
        if (clusters.dropLast().any { $0.size != 2 }) {
            Terminal.log(.error, "Clusters invalid: \(clusters)")
            return nil
        }

        // Create Level
        var remainingLetters = GameColor.allLetters
        let targets = clusters.dropLast().reduce(into: [GameColor: Level.Target]()) { targets, cluster in
            let start = cluster.objects[0].position
            let end = cluster.objects[1].position
            let color = GameColor(letter: remainingLetters.removeFirst())
            targets[color] = Level.Target(color: color, point1: start, point2: end)
        }

        return Level(targets: targets, boardSize: screen.board.size)
    }

    /// Find the board inside the given image.
    private func findBoard(in image: Image, verbose: Bool = false) -> BoardLayout? {
        // Find point on the edge of the board
        guard let (start, color) = findBoardMargin(in: image) else {
            if verbose { Terminal.log(.error, "Couldn't find board margin!") }
            return nil
        }

        // Find board AABB
        let boardMargin = color.withTolerance(0.2)
        guard let edge = EdgeDetector.search(in: image, shapeColor: boardMargin, from: start, angle: .north) else { return nil }
        let aabb = SmallestAABB.containing(edge)

        // Check dimension match
        guard aabb.width.isAlmostEqual(to: aabb.height, tolerance: 3) else {
            if verbose { Terminal.log(.error, "Board dimensions mismatch (\(aabb))") }
            return nil
        }

        // Find board size
        guard let size = findBoardSize(in: image, for: aabb, boardMarginColor: boardMargin) else {
            if verbose { Terminal.log(.error, "Couldn't determine board size!") }
            return nil
        }

        return BoardLayout(aabb: aabb, size: size)
    }

    /// Find a single pixel on the edge of the board.
    private func findBoardMargin(in image: Image) -> (Pixel, Color)? {
        let background = Color.black.withTolerance(0.25)

        let leftCenter = Pixel(0, image.height / 2)
        let rightCenter = Pixel(image.width - 1, image.height / 2)

        // Walk max. 4 pixels inwards from left or right as the board immediately starts at the image margin
        let fromLeft = StraightPath(start: leftCenter, angle: .east, bounds: image.bounds).limited(by: 4)
        let fromRight = StraightPath(start: rightCenter, angle: .west, bounds: image.bounds).limited(by: 4)

        guard let pixel = image.findFirstPixel(matching: !background, on: fromLeft) ?? image.findFirstPixel(matching: !background, on: fromRight) else {
            return nil
        }

        return (pixel, image.color(at: pixel))
    }

    // Find the size of the board.
    private func findBoardSize(in image: Image, for board: AABB, boardMarginColor: ColorMatch) -> Int? {
        let start = board.rect.origin.nearestPixel + Delta(3, 3)
        let east = StraightPath(start: start, angle: .east, bounds: image.bounds)
        guard let first = image.findFirstPixel(matching: boardMarginColor, on: east) else { return nil }

        // Determine number of boxes
        let boxSize = first.x - Int(board.rect.origin.x)
        let size = board.width / CGFloat(boxSize)
        return Int(round(size))
    }
}

/// Helper struct for level-color clustering.
struct PositionAndColor: DistanceMeasurable {
    let position: Position
    let color: Color

    func distance(to other: PositionAndColor) -> Double {
        color.distance(to: other.color)
    }
}
