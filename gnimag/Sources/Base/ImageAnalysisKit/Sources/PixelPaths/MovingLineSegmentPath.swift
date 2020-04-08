//
//  Created by David Knothe on 08.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation
import Geometry
import Image

/// A MovingLineSegmentPath consists of subpaths, each of which is a LineSegment.
/// In each LineSegment-subpath, a defined number of points are yielded. After the subpath is exhausted, the LineSegment is moved by a given vector.
public final class MovingLineSegmentPath: PixelPath {
    /// Pixels outside these bounds are skipped, but these bounds are not considered in random point generation (i.e. they do count to `numberOfPointsPerLineSegment`).
    /// This means, line segments which cross the bounds yield less pixels in`next`.
    private let bounds: Bounds

    /// LineSegment-movement related properties.
    private var remainingLineSegmentMovements: Int
    private let movementVector: CGPoint

    /// Properties related to the current LineSegment-subpath
    private var currentLineSegment: LineSegment
    private var currentLineSegmentRemainingPoints: [CGPoint] = []

    private let randomness: Double
    private let numberOfPointsPerLineSegment: Int

    /// Default initializer.
    public init(initialLineSegment: LineSegment, numOfLineSegments: Int, movementAngle: Angle, movementSpeed: CGFloat, randomness: Double, numberOfPointsPerLineSegment: Int, bounds: Bounds) {
        self.bounds = bounds
        self.remainingLineSegmentMovements = numOfLineSegments - 1
        self.movementVector = Circle(center: .zero, radius: movementSpeed).point(at: movementAngle)
        self.currentLineSegment = initialLineSegment
        self.randomness = randomness
        self.numberOfPointsPerLineSegment = Swift.min(numberOfPointsPerLineSegment, Int(ceil(initialLineSegment.length)))

        super.init()
        self.currentLineSegmentRemainingPoints = randomPointsOnCurrentLineSegment()
    }

    /// Yield the next point on the current line segment. Move the line segment if it is exhausted.
    public override func next() -> Pixel? {
        if currentLineSegmentRemainingPoints.isEmpty {
            if !moveLineSegment() { return nil }
            currentLineSegmentRemainingPoints = randomPointsOnCurrentLineSegment()
        }

        let pixel = currentLineSegmentRemainingPoints.removeFirst().nearestPixel
        return bounds.contains(pixel) ? pixel : next()
    }

    /// Move the current line segment by `movementVector` and decrease `remainingLineSegmentMovements`.
    /// If all line movements were already exhausted, return false.
    private func moveLineSegment() -> Bool {
        if remainingLineSegmentMovements <= 0 { return false }
        remainingLineSegmentMovements -= 1

        currentLineSegment = LineSegment(from: currentLineSegment.startPoint + movementVector, to: currentLineSegment.endPoint + movementVector)
        return true
    }
    
    /// Get `numberOfPointsPerLineSegment` random points on the current line segment.
    private func randomPointsOnCurrentLineSegment() -> [CGPoint] {
        let range = SimpleRange<Double>(from: 0, to: Double(currentLineSegment.length))
        let tValues = RandomPoints.on(range, randomness: randomness, minDistance: 1, numPoints: numberOfPointsPerLineSegment)!

        return tValues.map { t in
            currentLineSegment.startPoint + CGFloat(t) * currentLineSegment.normalizedDirection
        }
    }
}
