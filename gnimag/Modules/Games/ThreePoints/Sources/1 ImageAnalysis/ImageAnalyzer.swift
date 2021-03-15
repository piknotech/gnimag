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
    /// Returns nil if the screen layout couldn't be detected.
    func initialize(with image: Image) -> ScreenLayout? {
        precondition(!isInitialized)

        // Find prism and top color
        guard let prism = findPrism(in: image) else { return nil }
        guard validate(prism, in: image) else { return nil }

        let xCenter = Double(image.width) / 2
        screen = ScreenLayout(dotCenterX: xCenter, prism: prism)

        isInitialized = true
        return screen
    }

    /// Find all dots and determine the prism state.
    func analyze(image: Image) -> AnalysisResult? {
        guard let prism = state(of: screen.prism, in: image) else { return nil }

        return AnalysisResult(prismState: prism, dots: [])
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

        guard circumcircle.center.x.isAlmostEqual(to: CGFloat(pixel.x), tolerance: 2),
            circumcircle.point(at: .south).y.isAlmostEqual(to: aabb.rect.minY, tolerance: 2),
            (2 * circumcircle.center.x).isAlmostEqual(to: aabb.rect.minX + aabb.rect.maxX, tolerance: 3) else {
                return nil
        }

        return ScreenLayout.Prism(circumcircle: circumcircle)
    }

    /// Validate whether the prism colors match together.
    private func validate(_ prism: ScreenLayout.Prism, in image: Image) -> Bool {
        let angles: [Angle] = [0, 1, 2].map { i -> Angle in
            Angle(Double.pi/2 - Double(i) * 2/3 * Double.pi)
        }

        let smallCircle = Circle(center: prism.circumcircle.center, radius: prism.circumcircle.radius / 4)
        let colors = angles.compactMap {
            DotColor(from: image.color(at: smallCircle.point(at: $0).nearestPixel))
        }

        // Validate colors
        return colors.count == 3 && colors[0].next == colors[1] && colors[1].next == colors[2] && colors[2].next == colors[0]
    }

    /// Determine whether the prism is rotating and find its top color.
    /// This won't work when an orange dot is currently entering the prism.
    private func state(of prism: ScreenLayout.Prism, in image: Image) -> AnalysisResult.PrismState? {
        // Find orange pixel inside prism
        let orange = DotColor.orange.referenceColor.withTolerance(0.15)
        let path = ExpandingCirclePath(center: prism.circumcircle.center.nearestPixel, bounds: image.bounds).limited(by: 100)
        guard let pixel = image.findFirstPixel(matching: orange, on: path) else { return nil }

        // Detect orange edge
        guard let edge = EdgeDetector.search(in: image, shapeColor: orange, from: pixel, angle: .zero) else { return nil }
        let obb = SmallestOBB.containing(edge)

        // Integrity tests
        let width = max(obb.width, obb.height), height = min(obb.width, obb.height)
        let radius = prism.circumcircle.radius
        guard width.isAlmostEqual(to: sqrt(3) * radius, tolerance: 0.15 * radius),
            height.isAlmostEqual(to: 0.5 * radius, tolerance: 0.1 * radius) else { return nil }

        // Calculate position of orange: 0 is top, 1 is left, 2 is right; in-between is during rotation
        let angle = PolarCoordinates.angle(for: obb.center, respectiveTo: prism.circumcircle.center)
        var position = (angle - .pi / 2) / (2 * .pi / 3)
        if position < 0 { position += 3 }

        func iterate<A>(_ s: A, _ f: (A) -> A, _ n: Int) -> A {
            n == 0 ? s : iterate(f(s), f, n-1)
        }

        if abs(position - round(position)) < 0.05 {
            // Idle
            let p = Int(round(position)) % 3
            let color = iterate(DotColor.orange, \.next, p)
            return .idle(top: color)
        }
        else {
            // Rotating
            let p = Int(ceil(position)) % 3
            let color = iterate(DotColor.orange, \.next, p)
            return .rotating(towards: color)
        }
    }
}
