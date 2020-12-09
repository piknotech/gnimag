//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image
import ImageAnalysisKit
import LoggingKit
import TestingTools

// Required to redeclare the & operator which was publicly defined in LoggingKit
infix operator &

/// ImageAnalyzer provides a method for analyzing an image.
class ImageAnalyzer {
    /// The shared playfield. It does not change during the game.
    private var playfield: Playfield!

    private var lastPlayer: Player?
    private var lastColoring: Coloring?

    /// The debug logger and a shorthand form for the current debug frame.
    private let debugLogger: DebugLogger
    private var debug: DebugFrame.ImageAnalysis { debugLogger.currentFrame.imageAnalysis }

    /// The tolerance for all ColorMatch operations.
    private let tolerance = 20%

    /// Default initializer.
    init(debugLogger: DebugLogger) {
        self.debugLogger = debugLogger
    }

    /// Analyze the image. Use the hints to accomplish more performant or better analysis.
    func analyze(image: Image, hints: AnalysisHints) -> Result<AnalysisResult, AnalysisError> {
        debug.image = image

        // Find coloring
        guard let coloring = findColoring(in: image) ?? lastColoring else {
            return .failure(.error) & {debug.outcome = .error}
        }
        debug.coloring.result = coloring

        // Decide whether player has crashed
        if coloring.crashColor.matches(coloring.theme) {
            return .failure(.crashed) & {debug.outcome = .crashed}
        }

        // Find playfield (only at first call)
        playfield ??= findPlayfield(in: image, with: coloring)
        if playfield == nil {
            return .failure(.error) & {debug.outcome = .error}
        }
        debug.playfield.result = playfield

        // Find player
        guard let (player, playerOBB) = findPlayer(in: image, with: coloring, expectedPlayer: hints.expectedPlayer) else {
            return .failure(.error) & {debug.outcome = .error}
        }
        debug.player.result = player

        // Verify that player position has changed
        if let old = lastPlayer, player.angle.isAlmostEqual(to: old.angle, tolerance: 1/1_000), player.height.isAlmostEqual(to: old.height, tolerance: 1/1_000) {
            return .failure(.samePlayerPosition) & {debug.outcome = .samePlayerPosition}
        } else {
            lastPlayer = player
        }

        // Find bars
        let bars = findBars(in: image, with: coloring, playerOBB: playerOBB)
        debug.bars.result = bars

        debug.outcome = .success
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
        let result = SimpleClustering.from(colors, maxDistance: 0.05)

        // Find largest cluster; must contain at least half of the pixels
        if result.largestCluster.size < 11 {
            return nil & {debug.coloring.failure = .init(pixels: pixels, clusters: result.clusters)}
        }

        let averageColor = result.largestCluster.objects.reduce(Color.zero) { sum, newColor in
            sum + newColor / Double(result.largestCluster.size)
        }

        return Coloring(theme: theme, secondary: averageColor)
    }

    /// Find the playfield.
    /// Call this method only once, at the start of the game.
    /// Because this method is only called once (not once per frame), there do not need to be any performance optimizations.
    private func findPlayfield(in image: Image, with coloring: Coloring) -> Playfield? {
        let leftCenter = Pixel(3, image.height / 2)
        let path = StraightPath(start: leftCenter, angle: .east, bounds: image.bounds)

        let theme = coloring.theme.withTolerance(tolerance)
        let secondary = coloring.secondary.withTolerance(tolerance)

        // Find inner and outer circles
        guard let outerPoint = image.findFirstPixel(matching: secondary, on: path),
            let innerPoint = image.findFirstPixel(matching: theme, on: path) else { return nil }

        let outerEdge = EdgeDetector.search(in: image, shapeColor: secondary , from: outerPoint, angle: .north)!
        let outerCircle = SmallestCircle.containing(outerEdge)

        let innerEdge = EdgeDetector.search(in: image, shapeColor: theme, from: innerPoint, angle: .north)!
        let innerCircle = SmallestCircle.containing(innerEdge)

        // Centers should be (nearly) identical
        guard innerCircle.center.distance(to: outerCircle.center) < 1 else { return nil }
        let center = (innerCircle.center + outerCircle.center) / 2

        return Playfield(center: center, innerRadius: Double(innerCircle.radius), fullRadius: Double(outerCircle.radius))
    }

    /// Find the player; also, return its OBB for further analysis.
    private func findPlayer(in image: Image, with coloring: Coloring, expectedPlayer: Player) -> (Player, OBB)? {
        let searchCenter = expectedPlayer.coords.position(respectiveTo: playfield.center).nearestPixel
        debug.player.searchCenter = searchCenter

        // Find eye or wing pixel via its unique color
        let path = ExpandingCirclePath(center: searchCenter, bounds: image.bounds).limited(by: 50_000)
        guard let eye = image.findFirstPixel(matching: coloring.eye, on: path) else {
            return nil & {debug.player.failure = .eyeNotFound}
        }
        debug.player.eyePosition = eye

        // Edge detection
        let blue = coloring.theme.withTolerance(tolerance)
        let limit = EdgeDetector.DetectionLimit.maxPixels(Int(8 * expectedPlayer.size)) // Normal is 4 * size

        // Find player edge using 4 different starting angles; this avoids problems when the inside is not uniformly blue
        var edges = [[Pixel]]()
        for i in 0 ..< 4 {
            let angle = expectedPlayer.coords.angle + CGFloat(i) * .pi / 2

            guard let edge = EdgeDetector.search(in: image, shapeColor: blue, from: eye, angle: Angle(angle), limit: limit) else { continue }
            edges.append(edge)
        }

        // 0 or 1 edges found: analysis error. 2 out of 4 edges are enough for a correctly detected player
        if edges.count < 2 {
            return nil & {debug.player.failure = .edgeTooLarge}
        }

        var obb = SmallestOBB.containing(edges.flatMap(id))
        obb = reorientate(obb: obb, respectiveTo: playfield.center)

        // Remove player's beak from OBB if it was detected by EdgeDetector
        if obb.width > obb.height + 1 {
            let axes = obb.rightHandedCoordinateAxes(respectiveTo: playfield.center)
            let clockwise = GameProperties.birdMovesClockwise(in: coloring.mode)
            let beakDirection = clockwise ? axes.right : -axes.right
            let offsetFromApparentCenterToActualCenter = (obb.width - obb.height) / 2
            let center = obb.center - offsetFromApparentCenterToActualCenter * beakDirection
            obb = OBB(center: center, width: obb.height, height: obb.height, rotation: obb.rotation)
        }

        // Construct player
        debug.player.obb = obb
        let coords = PolarCoordinates(position: obb.center, center: playfield.center)
        return (Player(coords: coords, size: Double(obb.height)), obb)
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

        // Only keep pixels which belong to a bar
        let blue = coloring.theme.withTolerance(tolerance)
        pixels.removeAll { pixel in
            !blue.matches(image.color(at: pixel))
        }

        // Fully locate each bar based on one interior pixel
        var innerOBBs = [OBB]() // Once a bar was evaluated, any pixels inside this bar are dismissed

        return pixels.compactMap { pixel in
            guard (innerOBBs.none { $0.contains(pixel.CGPoint) }) else { return nil }
            guard let (bar, innerOBB) = locateBar(from: pixel, in: image, with: coloring) else { return nil }
            innerOBBs.append(innerOBB.inset(by: (-2, -2))) // Bugfix: make OBB marginally larger
            return bar
        }
    }

    /// Find the bar which is described by the given cluster.
    /// Also return the OBB of the inner part of the bar.
    private func locateBar(from pixel: Pixel, in image: Image, with coloring: Coloring) -> (Bar, innerOBB: OBB)? {
        debug.bars.nextBarLocation()
        debug.bars.current.startPixel = pixel

        let blue = coloring.theme.withTolerance(tolerance)
        let limit = EdgeDetector.DetectionLimit.distance(to: pixel, maximum: playfield.freeSpace)

        // Find inner edge
        guard let innerEdge = EdgeDetector.search(in: image, shapeColor: blue, from: pixel, angle: .east, limit: limit) else {
            return nil & {debug.bars.current.failure = .innerEdge}
        }
        var innerOBB = SmallestOBB.containing(innerEdge)
        let angle1 = PolarCoordinates.angle(for: innerOBB.center, respectiveTo: playfield.center)
        debug.bars.current.innerOBB = innerOBB

        // Find outer edge
        let upPosition = PolarCoordinates.position(atAngle: angle1, height: CGFloat(playfield.fullRadius - 5), respectiveTo: playfield.center).nearestPixel
        debug.bars.current.upPosition = upPosition
        guard let outerEdge = EdgeDetector.search(in: image, shapeColor: blue, from: upPosition, angle: .east, limit: limit) else {
            return nil & {debug.bars.current.failure = .outerEdge}
        }
        var outerOBB = SmallestOBB.containing(outerEdge)
        debug.bars.current.outerOBB = outerOBB
        
        // Integrity checks, reorientate OBBs
        let angle2 = PolarCoordinates.angle(for: outerOBB.center, respectiveTo: playfield.center)
        let distance = Angle(angle1).distance(to: Angle(angle2))
        guard distance <= 0.02 else {
            return nil & {debug.bars.current.failure = .anglesDifferent(angle1: angle1, angle2: angle2)}
        }

        innerOBB = reorientate(obb: innerOBB, respectiveTo: playfield.center)
        outerOBB = reorientate(obb: outerOBB, respectiveTo: playfield.center)
        guard innerOBB.width.isAlmostEqual(to: outerOBB.width, tolerance: 3) else {
            return nil & {debug.bars.current.failure = .widthsDifferent(width1: innerOBB.width, width2: outerOBB.width)}
        }
        let width = Double(innerOBB.width + outerOBB.width) / 2

        // The inner obb is a tiny bit too large because of the non-zero width of the box
        let r = sqrt(playfield.innerRadius * playfield.innerRadius - 0.25 * width * width) // Pythagoras
        let correctInnerHeight = 2 + Double(innerOBB.height) - playfield.innerRadius + r // r ≈ playfield.radius

        let bar = Bar(
            width: Double(width),
            angle: Angle(angle1).midpoint(between: Angle(angle2)).value,
            innerHeight: correctInnerHeight,
            outerHeight: Double(outerOBB.height), // Does not need to be corrected
            holeSize: playfield.freeSpace - Double(innerOBB.height + outerOBB.height),
            color: coloring.theme
        )

        debug.bars.current.result = bar
        return (bar, innerOBB)
    }

    /// Swap the width and height of the OBB to match with the given direction, if required.
    /// This means: The OBB is aligned such that its "width" sides are about orthogonal to, and its "height" sides are about parallel to the direction from the obb's center to the given center point. This also changes the OBB's rotation if required.
    private func reorientate(obb: OBB, respectiveTo orientationCenter: CGPoint) -> OBB {
        let rotatedCenter = orientationCenter.rotated(by: -obb.rotation, around: obb.center)
        let angle = PolarCoordinates.angle(for: rotatedCenter, respectiveTo: obb.center)

        // Angle in [1/4*pi, 3/4*pi) u [5/4*pi, 7/4*pi): orientation is correct (upper and lower quarter of the circle)
        if [1, 2].contains(Int(angle * 4 / .pi) % 4) { // 1/2 is good, 0/3 isn't
            return obb
        } else {
            // Swap width and height
            let newRotation = obb.rotation + 0.5 * .pi
            let newAABB = AABB(center: obb.center, width: obb.height, height: obb.width)
            return OBB(aabb: newAABB, rotation: newRotation)
        }
    }
}
