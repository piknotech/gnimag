//
//  Created by David Knothe on 10.02.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

/// The sign of the value, either +1 or -1.
/// Returns 0 when the value is zero or NaN.
@_transparent
public func sign(_ x: Double) -> Double {
    if x < 0 { return -1 }
    if x > 0 { return 1 }
    return 0
}
