//
//  Created by David Knothe on 24.11.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import MacTestingTools

/// Contains information about a function that is useful for debugging.
public struct FunctionDebugInfo {
    public let function: Function

    /// The strokable which can be drawn onto a ScatterPlot.
    public let strokable: ScatterStrokable
}
