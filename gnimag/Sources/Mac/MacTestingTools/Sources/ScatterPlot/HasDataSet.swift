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
    /// DataPoints can be distinguished by giving them an abstract color, either odd or even.
    public enum Color {
        case odd
        case even

        internal var color: NSColor {
            switch self {
            case .odd: return .red
            case .even: return .black
            }
        }
    }

    /// The properties of the data point.
    public let x: Double
    public let y: Double
    public let color: Color

    /// Initialize the data point with an explicit color.
    public init(x: Double, y: Double, color: Color) {
        self.x = x
        self.y = y
        self.color = color
    }

    /// Initialize the data point with the default color, which is black.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
        self.color = .even
    }
}
