//
//  Created by David Knothe on 25.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import GameKit

extension Exercise {
    enum Result {
        case equal
        case notEqual
    }

    /// Parse the exercise and return the result.
    /// Return nil if one of the term couldn't be parsed.
    var result: Result? {
        let upper = Term(string: upperTerm)
        let lower = Term(string: lowerTerm)

        guard let upperValue = upper.evaluate(verbose: true),
              let lowerValue = lower.evaluate(verbose: true) else { return nil }

        return upperValue == lowerValue ? .equal : .notEqual
    }
}
