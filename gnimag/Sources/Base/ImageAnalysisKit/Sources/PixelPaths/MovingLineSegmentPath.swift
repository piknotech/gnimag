//
//  Created by David Knothe on 08.04.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Geometry
import Image

/// A MovingLineSegmentPath consists of subpaths, each of which is a LineSegment.
/// In each LineSegment-subpath, a defined number of points are yielded. After the subpath is exhausted, the LineSegment is moved by a given vector.
public final class MovingLineSegmentPath: PixelPath {
    /// LineSegment-movement related properties.
    private var remainingLineSegmentMovements: Int
    private let movementVector: CGPoint

    /// Properties related to the current LineSegment-subpath
    private var currentLineSegment: LineSegment
    private var currentLineSegmentRemainingPoints: [CGPoint] = []

    private let randomness: Double
    private let numberOfPointsPerLineSegment: Int

    /// Default initializer.
    public init(initialLineSegment: LineSegment, numOfLineSegments: Int, movementAngle: Angle, movementSpeed: CGFloat, randomness: Double, numberOfPointsPerLineSegment: Int) {
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

        return currentLineSegmentRemainingPoints.removeFirst().nearestPixel
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
        let values = RandomPoints.on(SimpleRange(from: 0, to: 1), randomness: randomness, minDistance: 1, numPoints: numberOfPointsPerLineSegment) ?? []

        return values.map {
            currentLineSegment.startPoint + CGFloat($0) * currentLineSegment.normalizedDirection
        }
    }
}
