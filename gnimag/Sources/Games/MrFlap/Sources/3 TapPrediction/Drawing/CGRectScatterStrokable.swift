//
//  Created by David Knothe on 22.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import TestingTools

/// Draws a CGRect which is given in data point space.
struct CGRectScatterStrokable: ScatterStrokable {
    let rect: CGRect

    func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        let rect = self.rect.intersection(scatterPlot.dataContentRect)

        let origin = scatterPlot.pixelPosition(of: (Double(rect.minX), Double(rect.minY)))
        let width = rect.width / scatterPlot.dataContentRect.width * scatterPlot.pixelContentRect.width
        let height = rect.height / scatterPlot.dataContentRect.height * scatterPlot.pixelContentRect.height

        return AABB(rect: CGRect(x: origin.x, y: origin.y, width: width, height: height))
    }
}
