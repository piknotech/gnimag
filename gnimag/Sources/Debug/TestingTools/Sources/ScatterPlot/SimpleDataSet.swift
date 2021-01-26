//
//  Created by David Knothe on 09.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A class which just allows easily storing data points, equipped with colors, to be drawn by ScatterPlot.
public final class SimpleDataSet: HasScatterDataSet {
    private let maxDataPoints: Int

    /// The raw data set.
    public var dataSet = [ScatterDataPoint]()

    /// Default initializer, creating an empty data set.
    public init(maxDataPoints: Int = 500) {
        self.maxDataPoints = maxDataPoints
    }

    /// Add a point to the data set.
    public func add(value: Double, time: Double, color: ScatterColor) {
        dataSet.append(ScatterDataPoint(x: time, y: value, color: color))
        dataSet.trim(maxCount: maxDataPoints)
    }

    // Forward methods and properties.
    public func removeFirst() { dataSet.removeFirst() }
    public func removeAll() { dataSet.removeAll() }
    public func removeLast() { dataSet.removeLast() }
    public var count: Int { dataSet.count }
}
