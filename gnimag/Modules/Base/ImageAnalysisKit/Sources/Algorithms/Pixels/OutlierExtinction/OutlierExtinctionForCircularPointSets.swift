//
//  Created by David Knothe on 01.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

public enum OutlierExtinctionForCircularPointSets {
    /// Remove all outliers from a set. Outliers are detected as follows:
    ///  • Calculate the median point of the set
    ///  • Calculate the distances to the median point; calculate the median distance
    ///  • Then, discard all points where the distance is far enough away from the median distance; to be precise, where |distance - medianDistance| > medianDistance * outlierDistanceThreshold.
    ///  Therefore, a lower threshold means that more points will be removed in general.
    ///  This method is only sensible when the points are expected to have approximately the same distance to their median point, e.g. when detecting circles. For other shapes (where the distance to the median point varies by design), this method is useless.
    public static func removeOutliers(from set: [CGPoint], outlierDistanceThreshold threshold: CGFloat) -> [CGPoint] {
        guard set.count > 2 else { return set }

        // Median point
        let medX = set.map(\.x).median
        let medY = set.map(\.y).median
        let medianPoint = CGPoint(x: medX, y: medY)

        // Distances
        let distances = set.map(medianPoint.distance(to:))
        let medianDistance = distances.median

        // Return points with allowed distance
        return zip(set, distances).filter {
            let (_, distance) = $0
            return abs(distance - medianDistance) <= medianDistance * threshold
        } .map(\.0) // Convert (point, distance) back to (point)
    }
}

// MARK: Median
private extension Array where Element == CGFloat {
    /// Caclulate the median object of a non-empty array in O(n log n).
    var median: CGFloat {
        let sortedArray = sorted()
        if count % 2 != 0 {
            return sortedArray[count / 2]
        } else {
            return (sortedArray[count / 2] + sortedArray[count / 2 - 1]) / 2
        }
    }
}
