//
//  Created by David Knothe on 03.08.19.
//  Copyright © 2019 Piknotech. All rights reserved.
//

import Foundation

extension Sequence {
    /// Count the number of objects where "predicate" is fulfilled.
    public func count(where predicate: (Element) -> Bool) -> Int {
        filter(predicate).count
    }

    /// Check iff any element fulfills the predicate.
    public func any(where predicate: (Element) -> Bool) -> Bool {
        contains(where: predicate)
    }

    /// Check iff no element fulfills the predicate.
    public func none(where predicate: (Element) -> Bool) -> Bool {
        !contains(where: predicate)
    }
}
