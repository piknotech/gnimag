//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Image

/// Implement this protocol for Trackers or other objects that have 2-dimensional data you are interested in plotting using ScatterPlot.
public protocol Has2DDataSet {
    /// Return a 2D data set, consisting of x and y values.
    /// The x and y arrays should have the same size.
    func yieldDataSet() -> (xValues: [Double], yValues: [Double])
}
