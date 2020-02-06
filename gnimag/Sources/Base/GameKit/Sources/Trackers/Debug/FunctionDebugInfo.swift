//
//  Created by David Knothe on 24.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import TestingTools

/// Contains information about a function that is useful for debugging.
public struct FunctionDebugInfo {
    /// The function which is contained in `strokable`. Can be nil.
    public let function: Function?

    /// The strokable which can be drawn onto a ScatterPlot.
    public let strokable: ScatterStrokable

    /// The color of the path.
    public let color: ScatterColor

    /// The dash that is used to draw the graph.
    public let dash: DashType

    /// Default initializer.
    public init(function: Function?, strokable: ScatterStrokable, color: ScatterColor, dash: DashType) {
        self.function = function
        self.strokable = strokable
        self.color = color
        self.dash = dash
    }

    /// DashType defines a dash semantically, allowing trackers to provide values like "dashed" or "solid", separating them from the exact dash layout.
    public enum DashType {
        case dashed
        case solid

        /// The concrete dash that can be used for drawing onto ScatterPlot.
        public var concreteDash: Dash? {
            switch self {
            case .dashed:
                return Dash(on: 3, off: 3)
            case .solid:
                return nil
            }
        }
    }
}
