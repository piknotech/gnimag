//
//  Created by David Knothe on 22.11.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

/// ScatterStrokable defines its requirements on an abstract space and generates a concrete Strokable once it is given concrete information about the drawing space (which is defined by a ScatterPlot).
public protocol ScatterStrokable {
    /// Return the concrete strokable for drawing onto a specific ScatterPlot.
    func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable
}
