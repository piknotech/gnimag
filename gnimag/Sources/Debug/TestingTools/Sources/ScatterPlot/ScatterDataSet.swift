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

    /// Initialize the data point with the default color.
    public init(x: Double, y: Double) {
        self.init(x: x, y: y, color: .normal)
    }
}

/// DataPoints and functions can be distinguished by giving them an abstract color.
public enum ScatterColor {
    case normal
    case emphasize

    // Special values for CompositeTracker.
    case even
    case odd
    case inDecisionWindow
    case invalid

    case custom(Color)

    internal var concreteColor: Color {
        switch self {
        case .normal, .even:
            return .black

        case .odd:
            return .red

        case .inDecisionWindow:
            return .white

        case .invalid, .emphasize:
            return .lightBlue

        case .custom(let color):
            return color
        }
    }
}
