//
//  Created by David Knothe on 15.01.20.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import TestingTools

/// A composition of ScatterStrokables, which is drawn by drawing all components consecutively.
public struct MultiScatterStrokable: ScatterStrokable {
    private let components: [ScatterStrokable]

    /// Default initializer.
    public init(components: [ScatterStrokable]) {
        self.components = components
    }

    /// Return a MultiStrokable consisting of the concrete strokables of each component.
    public func concreteStrokable(for scatterPlot: ScatterPlot) -> Strokable {
        let strokables = components.map { $0.concreteStrokable(for: scatterPlot) }
        return MultiStrokable(components: strokables)
    }
}

/// A composition of Strokables, which is drawn by drawing all components consecutively.
public struct MultiStrokable: Strokable {
    private let components: [Strokable]

    /// Default initializer.
    public init(components: [Strokable]) {
        self.components = components
    }

    /// Draw all components consecutively, in the given order.
    public func stroke(onto context: CGContext) {
        for component in components {
            component.stroke(onto: context)
        }
    }
}
