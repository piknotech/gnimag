//
//  Created by David Knothe on 07.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import ImageInput

/// Implement this protocol for Trackers or other objects that have 2-dimensional data you are interested in plotting using ScatterPlot.
public protocol Has2DDataSet {
    /// Convert the instance to a CGImage.
    func yieldDataSet() -> (xValues: [Double], yValues: [Double])
}
