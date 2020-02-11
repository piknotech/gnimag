//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

extension Sequence {
    /// Count the number of objects where "predicate" is fulfilled.
    @_transparent
    public func count(where predicate: (Element) -> Bool) -> Int {
        filter(predicate).count
    }

    /// Check iff any element fulfills the predicate.
    @_transparent
    public func any(where predicate: (Element) -> Bool) -> Bool {
        contains(where: predicate)
    }

    /// Check iff no element fulfills the predicate.
    @_transparent
    public func none(where predicate: (Element) -> Bool) -> Bool {
        !contains(where: predicate)
    }
}
