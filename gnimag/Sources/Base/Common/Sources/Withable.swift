//
//  Created by David Knothe on 17.04.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

public protocol Withable { }

extension Withable {
    /// Modify an object using a block and return the result.
    @discardableResult
    public func with(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
