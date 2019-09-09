//
//  Created by David Knothe on 10.09.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//  

import HandySwift

extension Comparable {
    /// Extends `clamped` from HandySwift to the `RangeExpression` protocol itself.
    public func clamped<Range: RangeExpression>(to limits: Range) -> Self where Range.Bound == Self {
        if let range = limits as? ClosedRange<Self> { return clamped(to: range) }
        if let range = limits as? PartialRangeFrom<Self> { return clamped(to: range) }
        if let range = limits as? PartialRangeThrough<Self> { return clamped(to: range) }

        // Not supported
        return self
    }
}
