//
//  Created by David Knothe on 23.09.19.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

extension FloatingPoint {
    /// Test for approximate equality with an absolute tolerance.
    @_transparent
    public func isAlmostEqual(to other: Self, tolerance: Self) -> Bool {
        return abs(self - other) <= tolerance
    }
}
