//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An axis-aligned bounding box.

public struct AABB {
    public let rect: CGRect

    /// Default initializer.
    public init(rect: CGRect) {
        self.rect = rect
    }
}
