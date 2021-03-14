//
//  Created by David Knothe on 08.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Geometry
import Foundation
import Image
import ImageAnalysisKit

/// Height of the ad at the bottom. Varies depending on the device.
private let adHeight = 100

class ImageAnalyzer {
    /// States whether the ImageAnalyzer has been initialized by `initialize`.
    var isInitialized = false
    private var screen: ScreenLayout!

    /// Initialize the ImageAnalyzer by detecting the ScreenLayout using the first image.
    /// Also returns the current top color of the prism.
    /// Returns nil if the screen layout couldn't be detected.
    func initialize(with image: Image) -> (ScreenLayout, DotColor)? {
        precondition(!isInitialized)

        // Find prism and top color
        guard let prism = findPrism(in: image) else { return nil }
        guard let color = topColor(of: prism, in: image) else { return nil }

        let xCenter = Double(image.width) / 2
        screen = ScreenLayout(dotCenterX: xCenter, prism: prism)

        isInitialized = true
        return (screen, color)
    }

    /// Detect the prism in an image.
    private func findPrism(in image: Image) -> ScreenLayout.Prism? {
        let downmost = Pixel(image.width / 2, adHeight + 5)
        let path = StraightPath(start: downmost, angle: .north, bounds: image.bounds)
        let white = Color.white.withTolerance(0.1)

        // Find prism
        guard let pixel = image.findFirstPixel(matching: !white, on: path),
            let edge = EdgeDetector.search(in: image, shapeColor: !white, from: pixel, angle: .north, limit: .maxPixels(5000)) else {
            return nil
        }

        // Find and validate circumcircle
        let circumcircle = SmallestCircle.containing(edge)
        let aabb = SmallestAABB.containing(edge)
        let aabbSouth = aabb.center.y - aabb.height / 2

        guard circumcircle.center.x.isAlmostEqual(to: CGFloat(pixel.x), tolerance: 2),
            circumcircle.point(at: .south).y.isAlmostEqual(to: aabbSouth, tolerance: 2) else {
                return nil
        }

        return ScreenLayout.Prism(circumcircle: circumcircle)
    }

    /// Find the top color in a prism, given its circumcircle.
    /// Thereby, check whether the other colors match.
    private func topColor(of prism: ScreenLayout.Prism, in image: Image) -> DotColor? {
        let angles: [Angle] = [0, 1, 2].map { i -> Angle in
            Angle(Double.pi/2 - Double(i) * 2/3 * Double.pi)
        }

        let smallCircle = Circle(center: prism.circumcircle.center, radius: prism.circumcircle.radius / 4)
        let colors = angles.compactMap {
            DotColor(color: image.color(at: smallCircle.point(at: $0).nearestPixel))
        }

        // Validate that the colors match togehter
        guard colors.count == 3,
            colors[0].next == colors[1], colors[1].next == colors[2], colors[2].next == colors[0] else { return nil }

        return colors[0]
    }
}
