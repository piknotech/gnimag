//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit
import MacTestingTools

/// ImageAnalyzer provides a method for analyzing an image.
class ImageAnalyzer {
    /// The shared playfield. It does not change during the game.
    private var playfield: Playfield!

    private var lastPlayer: Player?
    private var lastColoring: Coloring?

    /// Analyze the image. Use the hints to accomplish more performant or better analysis.
    func analyze(image: Image, hints: AnalysisHints) -> Result<AnalysisResult, AnalysisError> {
        guard let coloring = findColoring(in: image) ?? lastColoring else {
            return .failure(.error)
        }

        // Find playfield at first call
        playfield ??= findPlayfield(in: image, with: coloring)
        if playfield == nil {
            return .failure(.error)
        }

        // Find player
        guard let (player, playerOBB) = findPlayer(in: image, with: coloring, expectedPlayer: hints.expectedPlayer) else {
            return .failure(.error)
        }

        // Verify that player position has changed
        if let old = lastPlayer, player.angle.isAlmostEqual(to: old.angle, tolerance: 1/1_000), player.height.isAlmostEqual(to: old.height, tolerance: 1/1_000) {
            return .failure(.samePlayerPosition)
        } else {
            lastPlayer = player
        }

        // Find bars
        let bars = findBars(in: image, with: coloring, playerOBB: playerOBB)

        return .success(AnalysisResult(player: player, playfield: playfield, coloring: coloring, bars: bars))
    }

    /// Find the coloring of the game.
    private func findColoring(in image: Image) -> Coloring? {
        // Step 1: use static pixel to find the main (theme) color
        let bottomLeft = Pixel(10, 10)
        let theme = image.color(at: bottomLeft)

        // Step 2: consider 21 pixels and determine their most frequent color to find the secondary color
        let circle = Circle(center: image.bounds.center.CGPoint, radius: CGFloat(image.width) / 4)
        let pixels = CirclePath.equidistantPixels(on: circle, numberOfPixels: 21)
        let colors = pixels.map(image.color(at:))
        let result = ConnectedChunks.from(colors, maxDistance: 0.05)

        // Find largest chunk; must contain at least half of the pixels
        if result.maxChunkSize < 11 { return nil }
        let averageColor = result.largestChunk.objects.reduce(Color.zero) { sum, newColor in
            return sum + newColor / Double(result.maxChunkSize)
        }

        return Coloring(theme: theme, secondary: averageColor)
    }

    /// Find the playfield.
    /// Call this method only once, at the start of the game.
    /// Because this method is only called once (not once per frame), there do not need to be any performance optimizations.
    private func findPlayfield(in image: Image, with coloring: Coloring) -> Playfield? {
        let screenCenter = Pixel(image.width / 2, image.height / 2)

        // Find inner circle with the following sequence: [blue, white, blue, white]
        let innerSequence = ColorMatchSequence(tolerance: 0.1, colors: [coloring.theme, coloring.secondary, coloring.theme, coloring.secondary])
        guard let innerContour = RayShooter.findContour(in: image, center: screenCenter, numRays: 7, colorSequence: innerSequence) else { return nil }
        let innerCircle = SmallestCircle.containing(innerContour.map(CGPoint.init))

        // Find outer circle with the following sequence: [blue, white, blue, white, blue]
        let outerSequence = ColorMatchSequence(tolerance: 0.1, colors: [coloring.theme, coloring.secondary, coloring.theme, coloring.secondary, coloring.theme])
        guard let outerContour = RayShooter.findContour(in: image, center: screenCenter, numRays: 7, colorSequence: outerSequence) else { return nil }
        let outerCircle = SmallestCircle.containing(outerContour.map(CGPoint.init))

        // Centers should be (nearly) identical
        guard innerCircle.center.distance(to: outerCircle.center) < 1 else { return nil }
        let center = (innerCircle.center + outerCircle.center) / 2

        playfield = Playfield(center: center, innerRadius: Double(innerCircle.radius), fullRadius: Double(outerCircle.radius))
        return playfield
    }

    /// Find the player; also, return its OBB for further analysis.
    private func findPlayer(in image: Image, with coloring: Coloring, expectedPlayer: Player) -> (Player, OBB)? {
        let searchCenter = expectedPlayer.coords.position(respectiveTo: playfield.center).nearestPixel

        // Find eye or wing pixel via its unique color
        let path = ExpandingCirclePath(center: searchCenter, bounds: image.bounds).limited(by: 50_000)
        guard let eye = image.findFirstPixel(matching: coloring.eye.withTolerance(0.1), on: path) else { return nil }

        // Find edge of player and calculate its OBB
        let blue = coloring.theme.withTolerance(0.1)
        let limit = EdgeDetector.DetectionLimit.maxPixels(Int(6 * expectedPlayer.size)) // Normal is 4 * size
        guard let edge = EdgeDetector.search(in: image, shapeColor: blue, from: eye, angle: expectedPlayer.coords.angle, limit: limit) else { return nil } // 6 * width is enough
        let obb = SmallestOBB.containing(edge.map(CGPoint.init))

        // Calculate player properties
        let coords = PolarCoordinates(position: obb.center, center: playfield.center)
        let size = Double(obb.width + obb.height) / 2
        return (Player(coords: coords, size: size), obb)
    }

    /// Find all bars.
    private func findBars(in image: Image, with coloring: Coloring, playerOBB: OBB) -> [Bar] {
        // Erase all blue things, execept the bars, from the image
        let innerCircle = Circle(center: playfield.center, radius: CGFloat(playfield.innerRadius) + 2)
        let outerCircle = Circle(center: playfield.center, radius: CGFloat(playfield.fullRadius) - 2)
        let insetOBB = playerOBB.inset(by: (-2, -2))
        let image = ShapeErasedImage(image: image, shapes: [.shape(innerCircle), .anti(outerCircle), .shape(insetOBB)])

        // Find one (or more) point inside each bar
        let circle = Circle(center: playfield.center, radius: CGFloat(playfield.innerRadius) + 5)
        var pixels = CirclePath.equidistantPixels(on: circle, numberOfPixels: 64)

        pixels.removeAll { pixel in // Remove pixels which do not belong to a bar
            image.color(at: pixel).distance(to: coloring.theme) > 0.1
        }

        // Fully locate each bar based on one interior pixel
        var innerOBBs = [OBB]() // Once a bar was evaluated, any pixels inside this bar are dismissed

        return pixels.compactMap { pixel in
            guard (innerOBBs.none { $0.contains(pixel.CGPoint) }) else { return nil }
            guard let (bar, innerOBB) = locateBar(from: pixel, in: image, with: coloring) else { return nil }
            innerOBBs.append(innerOBB)
            return bar
        }
    }

    /// Find the bar which is described by the given chunk.
    /// Also return the OBB of the inner part of the bar.
    private func locateBar(from pixel: Pixel, in image: Image, with coloring: Coloring) -> (Bar, innerOBB: OBB)? {
        let insideBar = coloring.theme.withTolerance(0.1)
        let limit = EdgeDetector.DetectionLimit.distance(to: pixel, maximum: playfield.freeSpace)

        // Find inner edge
        guard let innerEdge = EdgeDetector.search(in: image, shapeColor: insideBar, from: pixel, angle: 0, limit: limit) else { return nil }
        let innerOBB = SmallestOBB.containing(innerEdge.map(CGPoint.init))

        let angle1 = PolarCoordinates.angle(for: innerOBB.center, respectiveTo: playfield.center)

        // Find outer edge
        let upPosition = PolarCoordinates.position(atAngle: angle1, height: CGFloat(playfield.fullRadius - 5), respectiveTo: playfield.center).nearestPixel
        guard let outerEdge = EdgeDetector.search(in: image, shapeColor: insideBar, from: upPosition, angle: 0, limit: limit) else { return nil }
        let outerOBB = SmallestOBB.containing(outerEdge.map(CGPoint.init))

        // Integrity checks, reorientate OBBs
        let angle2 = PolarCoordinates.angle(for: outerOBB.center, respectiveTo: playfield.center)
        guard angle1.isAlmostEqual(to: angle2, tolerance: 0.02) else { return nil }

        let (width1, innerHeight) = reorientate(obb: innerOBB, respectiveTo: playfield.center)
        let (width2, outerHeight) = reorientate(obb: outerOBB, respectiveTo: playfield.center)
        guard width1.isAlmostEqual(to: width2, tolerance: 2) else { return nil }
        let width = Double(width1 + width2) / 2

        // The inner obb is a tiny bit too large because of the non-zero width of the box
        let r = sqrt(playfield.innerRadius * playfield.innerRadius - 0.25 * width * width) // Pythagoras
        let correctInnerHeight = 2 + Double(innerHeight) - playfield.innerRadius + r // r ≈ playfield.radius

        let bar = Bar(
            width: Double(width),
            angle: Double(angle1 + angle2) / 2,
            innerHeight: correctInnerHeight,
            outerHeight: Double(outerHeight), // Does not need to be corrected
            holeSize: playfield.freeSpace - Double(innerHeight + outerHeight)
        )

        return (bar, innerOBB)
    }

    /// Swap the width and height of the OBB to match with the given direction, if required.
    /// This means: The OBB is aligned such that its "width" sides are about orthogonal to, and its "height" sides are about parallel to the direction from the obb's center to the given center point.
    /// Instead of returning a new OBB, just return the width and the height (as the obb's center is not changed, just width and height may be swapped).
    private func reorientate(obb: OBB, respectiveTo orientationCenter: CGPoint) -> (width: CGFloat, height: CGFloat) {
        let rotatedCenter = orientationCenter.rotated(by: -obb.rotation, around: obb.center)
        let angle = PolarCoordinates.angle(for: rotatedCenter, respectiveTo: obb.center)

        // Angle in [1/4*pi, 3/4*pi) u [5/4*pi, 7/4*pi): orientation is correct (upper and lower quarter of the circle)
        if [1, 2].contains(Int(angle * 4 / .pi) % 4) { // 1/2 is good, 0/3 isn't
            return (obb.width, obb.height)
        } else {
            return (obb.height, obb.width) // Swap
        }
    }
}
