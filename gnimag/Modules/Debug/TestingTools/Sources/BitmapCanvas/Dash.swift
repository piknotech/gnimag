//
//  Created by David Knothe on 27.11.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// Dash defines a dash pattern that is used to draw lines.
public struct Dash {
    public let on: CGFloat
    public let off: CGFloat

    /// The lenghts of the dash pattern as required by CGContext.
    internal var lengths: [CGFloat] { [on, off] }

    /// Default initializer.
    public init(on: CGFloat, off: CGFloat) {
        self.on = on
        self.off = off
    }
}
