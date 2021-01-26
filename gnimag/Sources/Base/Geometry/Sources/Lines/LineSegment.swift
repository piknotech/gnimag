//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Common
import Foundation

/// A line segment connecting two points.
public struct LineSegment {
    public let startPoint: CGPoint
    public let endPoint: CGPoint

    public var length: CGFloat

    /// Default initializer.
    public init(from startPoint: CGPoint, to endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.length = (startPoint - endPoint).length
    }
}

extension LineSegment: LineType {
    public var isTrivial: Bool {
        startPoint == endPoint
    }

    public var normalizedDirection: CGPoint {
        (endPoint - startPoint).normalized
    }

    public var normalizedBounds: SimpleRange<CGFloat> {
        return SimpleRange(from: 0, to: length)
    }
}
