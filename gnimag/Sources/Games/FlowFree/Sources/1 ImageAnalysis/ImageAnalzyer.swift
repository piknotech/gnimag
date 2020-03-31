//
//  Created by David Knothe on 29.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit

/// ImageAnalyzer extracts levels from images.
class ImageAnalyzer {
    /// The ScreenLayout which is available after the first successful `analyze` call.
    private(set) var screen: ScreenLayout!

    /// Analyze an image; return the level.
    /// Returns nil if no board or valid level is found in the image.
    func analyze(image: Image) -> Level? {
        // Find board & screen layout if required
        if screen == nil {
            guard let board = findBoard(in: image) else { return nil }
            screen = ScreenLayout(board: board, screenSize: CGSize(width: image.width, height: image.height))
        }

        return findLevel(in: image)
    }

    /// Find the level in an image using the existing board layout.
    private func findLevel(in image: Image) -> Level? {
        let elements = (Array(0 ..< screen.board.size) × Array(0 ..< screen.board.size)).map { (x, y) -> PositionAndColor in
            let center = screen.board.center(ofCell: (x, y)).nearestPixel
            return PositionAndColor(position: Position(x: x, y: y), color: image.color(at: center))
        }

        let result = SimpleClustering.from(elements, maxDistance: 0.1)
        let clusters = result.clusters.sorted { $0.size < $1.size }

        // Check cluster validity: all clusters (except the background color) must have 2 elements
        if (clusters.dropLast().any { $0.size != 2 }) {
            Terminal.log(.error, "Clusters invalid: \(clusters)")
            return nil
        }

        let levelColors = clusters.dropLast().map { cluster -> Level.Color in
            let start = cluster.objects[0].position
            let end = cluster.objects[1].position
            return Level.Color(start: start, end: end)
        }

        return Level(colors: levelColors, boardSize: screen.board.size)
    }

    /// Find the board inside the given image.
    private func findBoard(in image: Image) -> BoardLayout? {
        // Find point on the edge of the board
        guard let (start, color) = findBoardMargin(in: image) else {
            Terminal.log(.error, "Couldn't find board margin!")
            return nil
        }

        // Find board AABB
        let boardMargin = color.withTolerance(0.1)
        guard let edge = EdgeDetector.search(in: image, shapeColor: boardMargin, from: start, angle: .north) else { return nil }
        let aabb = SmallestAABB.containing(edge)

        // Check dimension match
        guard aabb.width.isAlmostEqual(to: aabb.height, tolerance: 3) else {
            Terminal.log(.error, "Board dimensions mismatch (\(aabb))")
            return nil
        }

        // Find board size
        guard let size = findBoardSize(in: image, for: aabb, boardMarginColor: boardMargin) else {
            Terminal.log(.error, "Couldn't determine board size!")
            return nil
        }

        return BoardLayout(aabb: aabb, size: size)
    }

    /// Find a single pixel on the edge of the board.
    private func findBoardMargin(in image: Image) -> (Pixel, Color)? {
        let background = Color.black.withTolerance(0.25)

        let leftCenter = Pixel(0, image.height / 2)
        let rightCenter = Pixel(image.width - 1, image.height / 2)

        // Walk max. 3 pixels inwards from left or right as the board immediately starts at the image margin
        let fromLeft = StraightPath(start: leftCenter, angle: .east, bounds: image.bounds).limited(by: 3)
        let fromRight = StraightPath(start: rightCenter, angle: .west, bounds: image.bounds).limited(by: 3)

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
