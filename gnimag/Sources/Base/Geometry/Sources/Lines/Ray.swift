//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Common
import Foundation

/// A ray, starting at a point and continuing in one direction.
public struct Ray {
    public let startPoint: CGPoint
    public let normalizedDirection: CGPoint

    /// Default initializer.
    public init(startPoint: CGPoint, direction: CGPoint) {
        self.startPoint = startPoint
        normalizedDirection = direction.normalized
    }
}

extension Ray: LineType {
    public var isTrivial: Bool {
        normalizedDirection.isZero
    }

    public var normalizedBounds: SimpleRange<CGFloat> {
        return .positiveHalfOpen
    }
}
