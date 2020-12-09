//
//  Created by David Knothe on 22.01.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import TestingTools

/// Draws a CGRect which is given in data point space.
public struct CGRectScatterStrokable: ScatterStrokable {
    public let rect: CGRect

    /// Default initializer.
    public init(rect: CGRect) {
        self.rect = rect
    }

    /// Convert the rect into pixel space.
    public func concreteStrokable(for frame: ScatterFrame) -> Strokable {
        let rect = self.rect.intersection(frame.dataContentRect)

        let origin = frame.pixelPosition(of: (Double(rect.minX), Double(rect.minY)))
        let width = rect.width / frame.dataContentRect.width * frame.pixelContentRect.width
        let height = rect.height / frame.dataContentRect.height * frame.pixelContentRect.height

        return AABB(rect: CGRect(x: origin.x, y: origin.y, width: width, height: height))
    }
}
