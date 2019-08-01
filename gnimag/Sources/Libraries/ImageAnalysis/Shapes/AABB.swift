//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An axis-aligned bounding box.

public struct AABB {
    /// The bounds of the box. The bounds are LLO, meaning the origin is in the lower left corner.
    public let rect: CGRect

    /// Default initializer.
    public init(rect: CGRect) {
        self.rect = rect
    }
}
