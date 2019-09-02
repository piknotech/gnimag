//
//  Created by David Knothe on 22.06.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput
import ImageAnalysisKit
import MacTestingTools

/// ImageAnalyzer provides a method for analyzing an image.
class ImageAnalyzer {
    /// The shared playfield. It does not change during the game.
    private var playfield: Playfield!
    
    /// Analyze the image. Use the hints to accomplish more performant or better analysis.
    func analyze(image: Image, hints: AnalysisHints) -> Result<AnalysisResult, AnalysisError> {
        guard let coloring = findColoring(in: image) else {
            // ...
            return .failure(.unspecified) // DON'T FAIL, use last coloring!?
        }

        let playfield = findPlayfield(in: image, with: coloring)!

        let canvas = BitmapCanvas(image: image)
        canvas.drawCircle(center: playfield.center, radius: CGFloat(playfield.innerRadius), with: .black, alpha: 1, strokeWidth: 2)
        canvas.drawCircle(center: playfield.center, radius: CGFloat(playfield.fullRadius), with: .black, alpha: 1, strokeWidth: 2)
        canvas.write(to: "/Users/David/Desktop/test.png")
        
        return .failure(.unspecified)
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
    private func findPlayfield(in image: Image, with coloring: Coloring) -> Playfield? {
        precondition(playfield == nil)

        // Go downwards from the screen center until finding the beginning of the "0"
        let screenCenter = Pixel(image.width / 2, image.height / 2)
        var downwardsPath: PixelPath = StraightPath(start: screenCenter, angle: .pi, bounds: image.bounds)
        let zeroPosition = image.findFirstPixel(matching: coloring.secondary.withTolerance(0.1), on: &downwardsPath)!

        // Now find the edge of the inner circle (further going downwards)
        let innerEdge = EdgeDetector.search(in: image, shapeColor: coloring.theme.withTolerance(0.1), from: zeroPosition, angle: .pi)!
        let innerCircle = SmallestCircle.containing(innerEdge.map(CGPoint.init))

        // Go lower, now being outside the inner circle
        var outsidePosition = innerCircle.center.nearestPixel
        outsidePosition.y += Int(innerCircle.radius) + 2
        let outerEdge = EdgeDetector.search(in: image, shapeColor: coloring.secondary.withTolerance(0.1), from: outsidePosition, angle: .pi)!
        let outerCircle = SmallestCircle.containing(outerEdge.map(CGPoint.init))

        // Centers should be (nearly) identical
        var center = innerCircle.center + outerCircle.center
        center = CGPoint(x: center.x / 2, y: center.y / 2)

        playfield = Playfield(center: center, innerRadius: Double(innerCircle.radius), fullRadius: Double(outerCircle.radius))
        return playfield
    }

    /// Find the player.
    private func findPlayer() -> Player? {
        // flügel oder auge detecten! entweder weiss oder schwarz je nach mode --> unique color
        // vorschlagene position im hint als start benutzen; dann: Batched SpiralWalk oder ExtendingCircleWalk
        // batched = immer 50 nächste werte direkt berechnet und in array gespeichert; trotzdem: performance vom next-call?
        // --> dann von dort aus so lange extenden in 16 richtungen bis farbe nicht mehr passt (ColorMatchSequence, wie oben), dann: enclosing quadrat
        return nil
    }

    /// Find all bars.
    private func findBars() -> [Bar] {
        // zb. 48 punkte im kreis (c=playfield.center, r=playfield.innerRadius+5) anschauen; alles wo matcht speichern
        // dann: die matches (linearified) verklumpen --> 4 klumpen
        // jeden klumpen finalizen: mitte finden, von oben und unten schauen wie lang
        return []
    }
}
