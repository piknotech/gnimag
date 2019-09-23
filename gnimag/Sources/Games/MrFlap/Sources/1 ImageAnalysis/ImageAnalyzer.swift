//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

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
        playfield = playfield ?? findPlayfield(in: image, with: coloring)!
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
    /// Also, there is no error handling – we just assume that the image meets our expectations.
    private func findPlayfield(in image: Image, with coloring: Coloring) -> Playfield? {
        let screenCenter = Pixel(image.width / 2, image.height / 2)

        // Find inner circle with the following sequence: [blue, white, blue, white]
        let innerSequence = ColorMatchSequence(tolerance: 0.1, colors: [coloring.theme, coloring.secondary, coloring.theme, coloring.secondary])
        let innerContour = RayShooter.findContour(in: image, center: screenCenter, numRays: 7, colorSequence: innerSequence)!
        let innerCircle = SmallestCircle.containing(innerContour.map(CGPoint.init))

        // Find outer circle with the following sequence: [blue, white, blue, white, blue]
        let outerSequence = ColorMatchSequence(tolerance: 0.1, colors: [coloring.theme, coloring.secondary, coloring.theme, coloring.secondary, coloring.theme])
        let outerContour = RayShooter.findContour(in: image, center: screenCenter, numRays: 7, colorSequence: outerSequence)!
        let outerCircle = SmallestCircle.containing(outerContour.map(CGPoint.init))

        // Centers should be (nearly) identical
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
        // Step 1: consider 48 pixels directly above the inner circle and check which of them belong to bars
        let circle = Circle(center: image.bounds.center.CGPoint, radius: CGFloat(playfield.innerRadius) + 5)
        var pixels = CirclePath.equidistantPixels(on: circle, numberOfPixels: 48)

        pixels.removeAll { pixel in // Filter pixels which do not belong to any bar
            playerOBB.contains(pixel.CGPoint) ||
            image.color(at: pixel).distance(to: coloring.theme) > 0.1
        }

        // Merge together into chunks, each of which describes one bar
        let upperBoundForBarWidth = .pi / 8 * playfield.innerRadius // works for up to 8 bars
        let result = ConnectedChunks.from(pixels, maxDistance: upperBoundForBarWidth)

        // Step 2: fully locate each bar based on a chunk
        return result.chunks.compactMap {
            locateBar(from: $0.any, in: image, with: coloring)
        }
    }

    /// Find the bar which contains the given `startPixel`.
    private func locateBar(from startPixel: Pixel, in image: Image, with coloring: Coloring) -> Bar? {
        let insideBar = coloring.theme.withTolerance(0.1)

        /// Step 1: find center point by moving left and right as far as possible
        let angleApprox = PolarCoordinates.angle(for: startPixel.CGPoint, respectiveTo: playfield.center)
        let left = StraightPath(start: startPixel, angle: angleApprox + .pi / 2, bounds: image.bounds)
        let right = StraightPath(start: startPixel, angle: angleApprox - .pi / 2, bounds: image.bounds)

        guard let a = image.findFirstPixel(matching: .not(insideBar), on: left),
              let b = image.findFirstPixel(matching: .not(insideBar), on: right) else { return nil }

        // Use correct angle to go upwards
        let center = (a.CGPoint + b.CGPoint) / 2
        let angle = PolarCoordinates.angle(for: center, respectiveTo: playfield.center)
        let upwards = StraightPath(start: center.nearestPixel, angle: angle, bounds: image.bounds)
        let up = PolarCoordinates.position(atAngle: angle, height: CGFloat(playfield.fullRadius), respectiveTo: playfield.center)
        let downwards = StraightPath(start: up.nearestPixel, angle: .pi + angle, bounds: image.bounds)

        // Step 2: find the bottom edge and the top edge
        let bottomEdge = image.follow(path: upwards, untilFulfillingSequence: ColorMatchSequence(!insideBar))
        let topEdge = image.follow(path: downwards, untilFulfillingSequence: ColorMatchSequence(!insideBar))

        guard let bottom = bottomEdge.beforeFulfillment, let top = topEdge.beforeFulfillment else { return nil }

        let innerHeight = Double(bottom.CGPoint.distance(to: playfield.center)) - playfield.innerRadius
        let holeSize = top.distance(to: bottom)

        return Bar(
            width: a.distance(to: b), // Not 100% correct, but doesn't matter for small bar widths
            angle: Double(angle),
            innerHeight: innerHeight,
            outerHeight: playfield.freeSpace - innerHeight - holeSize,
            holeSize: holeSize
        )
    }
}
