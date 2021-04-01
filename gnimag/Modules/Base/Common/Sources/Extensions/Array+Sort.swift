//
//  Created by David Knothe on 15.03.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Foundation

extension Array {
    @_transparent
    public mutating func sort<A>(by key: (Element) -> A, _ smaller: (A, A) -> Bool) {
        sort { smaller(key($0), key($1)) }
    }

    @_transparent
    public mutating func sort<A: Comparable>(by key: (Element) -> A) {
        sort(by: key, <)
    }

    @_transparent
    public func sorted<A>(by key: (Element) -> A, _ smaller: (A, A) -> Bool) -> [Element] {
        var result = self
        result.sort(by: key, smaller)
        return result
    }

    @_transparent
    public func sorted<A: Comparable>(by key: (Element) -> A) -> [Element] {
        sorted(by: key, <)
    }
}
