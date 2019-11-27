//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Common
import Foundation

/// A line with a direction and an arbitrary starting point.
public struct Line {
    public let startPoint: CGPoint
    public let normalizedDirection: CGPoint

    /// Default initializer.
    public init(through point: CGPoint, direction: CGPoint) {
        startPoint = point
        normalizedDirection = direction.normalized
    }
}

extension Line: LineType {
    public var isTrivial: Bool {
        normalizedDirection.isZero
    }

    public var normalizedBounds: SimpleRange<CGFloat> {
        return .open
    }
}
