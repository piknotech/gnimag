//
//  Created by David Knothe on 19.02.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import TestingTools

/// A class which stores all data points (ScatterDataPoints) of a CompositeTracker (valid and invalid ones) and allows querying a specific subset of them.
internal class CompositeTrackerDataSet {
    /// A ScatterDataPoint, equipped with a segment index (which is required for filtering).
    struct SegmentDataPoint {
        let segmentIndex: Int
        let scatterDataPoint: ScatterDataPoint
    }

    private var dataPoints = [SegmentDataPoint]()

    /// Add a point to the data set.
    func add(value: Double, time: Double, segment: Int, color: ScatterColor) {
        let point = ScatterDataPoint(x: time, y: value, color: color)
        let dataPoint = SegmentDataPoint(segmentIndex: segment, scatterDataPoint: point)
        dataPoints.append(dataPoint)
    }

    /// Get all ScatterDataPoints for segments inside the given range.
    func dataPoints<Range: RangeExpression>(forSegmentIndicesInRange range: Range) -> [ScatterDataPoint] where Range.Bound == Int {
        dataPoints.filter { range.contains($0.segmentIndex) }.map(\.scatterDataPoint)
    }
}
