//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

/// Implement this protocol for Trackers or other objects that have 2-dimensional data you are interested in plotting using ScatterPlot.
public protocol HasScatterDataSet {
    /// Return the data set which should be plotted.
    var dataSet: [ScatterDataPoint] { get }
}

/// A data point for a scatter plot.
public struct ScatterDataPoint {
    /// The properties of the data point.
    public let x: Double
    public let y: Double
    public let color: ScatterColor

    /// Initialize the data point with an explicit color.
    public init(x: Double, y: Double, color: ScatterColor) {
        self.x = x
        self.y = y
        self.color = color
    }

    /// Initialize the data point with the default color, which is black.
    public init(x: Double, y: Double) {
        self.init(x: x, y: y, color: .even)
    }
}

/// DataPoints can be distinguished by giving them an abstract color.
public enum ScatterColor {
    case odd
    case even
    case invalid

    internal var NSColor: NSColor {
        switch self {
        case .odd: return .red
        case .even: return .black
        case .invalid: return .yellow
        }
    }
}
