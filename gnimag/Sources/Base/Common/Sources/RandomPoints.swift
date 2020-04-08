//
//  Created by David Knothe on 04.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

public enum RandomPoints {
    private static var xoshiro = Xoshiro()

    /// Returns an array of size `numPoints` containing evenly distributed points in the given range. The range must be regular.
    /// Additionally, the distance between each pair of points is at least `minimumDistance`.
    /// Returns nil if it is not possible to satisfy this condition.
    public static func on(_ range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int) -> [Double]? {
        guard let reducedRange = reducedRange(for: range, minimumDistance: minimumDistance, numPoints: numPoints) else { return nil }

        // Calculate N points on the reduced interval
        var points = random(in: reducedRange, count: numPoints)
        spreadOut(points: &points, minimumDistance: minimumDistance)
        return points
    }

    /// Works like `on` but, instead of specifying the minimum distance, specify the randomness.
    /// A randomness of 0 is a guaranteed uniform distribution, whereas a randomness of 1 is total randomness.
    public static func on(_ range: SimpleRange<Double>, randomness: Double, minDistance: Double = 0, numPoints: Int) -> [Double]? {
        let randomness = max(1, min(0, randomness))
        let distance = (1 - randomness) * range.size / Double(numPoints - 1)
        return on(range, minimumDistance: max(minDistance, distance), numPoints: numPoints)
    }

    /// Returns an array of size `numPoints` (positive) containing evenly distributed points in the given range. The range must be regular.
    /// Additionally, the distance between each pair of points is at least `minimumDistance`.
    /// Additionally, at least one point must be smaller than the given maximum value.
    /// Returns nil if it is not possible to satisfy this condition.
    public static func on(_ range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int, maximumValueForFirstPoint: Double) -> [Double]? {
        guard let reducedRange = reducedRange(for: range, minimumDistance: minimumDistance, numPoints: numPoints) else { return nil }

        // Create a point fulfilling the maximum value condition
        let firstPointRange = reducedRange.intersection(with: SimpleRange(from: -.infinity, to: maximumValueForFirstPoint))
        if firstPointRange.isEmpty { return nil } // `maximumValueForFirstPoint` too low
        let firstPoint = random(in: firstPointRange)

        // Calculate remaining points on the reduced interval
        var points = random(in: reducedRange, count: numPoints - 1)
        points.insert(firstPoint, at: 0)
        spreadOut(points: &points, minimumDistance: minimumDistance)
        return points
    }

    /// Calculate the reduced range for calculating random points in an interval with a minimum pairwise distance.
    /// Returns nil if the reduced range does not exist / would be empty.
    private static func reducedRange(for range: SimpleRange<Double>, minimumDistance: Double, numPoints: Int) -> SimpleRange<Double>? {
        let reducedLength = range.size - Double(numPoints - 1) * minimumDistance
        let reducedRange = SimpleRange(from: range.lower, to: range.lower + reducedLength)
        return reducedRange.isEmpty ? nil : reducedRange
    }

    /// Spread out points so that their minimum pairwise distance is at least `minimumDistance`.
    /// Thereby, the first point is left untouched, and the other ones are shifted to the right.
    private static func spreadOut(points: inout [Double], minimumDistance: Double) {
        points.sort()
        for i in 0 ..< points.count {
            points[i] += Double(i) * minimumDistance
        }
    }

    /// Returns random points in the given range. The range must be regular.
    private static func random(in range: SimpleRange<Double>, count: Int) -> [Double] {
        count.timesMake { random(in: range) }
    }

    /// Return a random point in the given range. The range must be regular.
    private static func random(in range: SimpleRange<Double>) -> Double {
        Double.random(in: range.lower ... range.upper, using: &xoshiro)
    }

    /// Throw a coin.
    public static func fiftyFifty() -> Bool {
        xoshiro.next() < .max / 2
    }
}
