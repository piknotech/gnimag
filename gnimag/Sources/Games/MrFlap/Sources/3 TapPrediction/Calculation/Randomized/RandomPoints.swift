//
//  Created by David Knothe on 04.02.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

enum RandomPoints {
    /// Returns an array of size `numPoints` containing evenly distributed points in the given range. The range must be regular.
    /// Additionally, the distance between each pair of points is at least `minimumDistance`.
    /// Returns nil if it is not possible to satisfy this condition.
    static func on(_ range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int) -> [Double]? {
        guard let reducedRange = reducedRange(for: range, minimumDistance: minimumDistance, numPoints: numPoints) else { return nil }

        // Calculate N points on the reduced interval
        let points = random(in: reducedRange, count: numPoints)
        return spreadOut(points: points, minimumDistance: minimumDistance)
    }

    /// Returns an array of size `numPoints` (positive) containing evenly distributed points in the given range. The range must be regular.
    /// Additionally, the distance between each pair of points is at least `minimumDistance`.
    /// Additionally, at least one point must be smaller than the given maximum value.
    /// Returns nil if it is not possible to satisfy this condition.
    static func on(_ range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int, maximumValueForFirstPoint: Double) -> [Double]? {
        guard let reducedRange = reducedRange(for: range, minimumDistance: minimumDistance, numPoints: numPoints) else { return nil }

        // Create a point fulfilling the maximum value condition
        let firstPointRange = reducedRange.intersection(with: SimpleRange(from: -.infinity, to: maximumValueForFirstPoint))
        if firstPointRange.isEmpty { return nil } // `maximumValueForFirstPoint` too low
        let firstPoint = random(in: firstPointRange)

        // Calculate remaining points on the reduced interval
        let points = [firstPoint] + random(in: reducedRange, count: numPoints - 1)
        return spreadOut(points: points, minimumDistance: minimumDistance)
    }

    /// Calculate the reduced range for calculating random points in an interval with a minimum pairwise distance.
    /// Returns nil if the reduced range does not exist / would be empty.
    private static func reducedRange(for range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int) -> SimpleRange<Double>? {
        let reducedLength = range.upper - range.lower - Double(numPoints - 1) * minimumDistance
        let reducedRange = SimpleRange(from: range.lower, to: range.lower + reducedLength)
        return reducedRange.isEmpty ? nil : reducedRange
    }

    /// Spread out points so that their minimum pairwise distance is at least `minimumDistance`.
    /// Thereby, the first point is left untouched, and the other ones are shifted to the right.
    private static func spreadOut(points: [Double], minimumDistance: Double) -> [Double] {
        points.sorted().enumerated().map { i, point in
            point + Double(i) * minimumDistance
        }
    }

    /// Returns random points in the given range. The range must be regular.
    private static func random(in range: SimpleRange<Double>, count: Int) -> [Double] {
        (0 ..< count).map { _ in random(in: range) }
    }

    /// Return a random point in the given range. The range must be regular.
    private static func random(in range: SimpleRange<Double>) -> Double {
        .random(in: range.lower ... range.upper)
    }
}
