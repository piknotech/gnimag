//
//  Created by David Knothe on 09.10.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

/// A class which just allows easily storing data points, equipped with colors, to be drawn by ScatterPlot.
public final class SimpleDataSet: HasScatterDataSet {
    public private(set) var dataSet = [ScatterDataPoint]()

    /// Default initializer, creating an empty data set.
    public init() {
    }

    /// Add a point to the data set.
    public func add(value: Double, time: Double, color: ScatterColor) {
        dataSet.append(ScatterDataPoint(x: time, y: value, color: color))
    }
}
