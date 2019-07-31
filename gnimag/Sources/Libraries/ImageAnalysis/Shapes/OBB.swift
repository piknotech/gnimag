//
//  Created by David Knothe on 31.07.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

/// An oriented bounding box.

public struct OBB {
    public let center: CGPoint
    public let width: Double
    public let height: Double

    /// The rotation, counterclockwise, in [-pi/2, pi/2].
    public let rotation: Double

    /// Default initializer.
    public init(center: CGPoint, width: Double, height: Double, rotation: Double) {
        self.center = center
        self.width = width
        self.height = height
        self.rotation = rotation
    }
}
