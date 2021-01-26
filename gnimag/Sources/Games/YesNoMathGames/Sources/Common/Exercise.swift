//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import GameKit

/// The result that ImageAnalyzer will yield for each successfully analyzed image.
struct Exercise: Equatable {
    let upperTerm: String
    let lowerTerm: String

    /// Compare two `Exercise`s for exact equality.
    static func ==(lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.upperTerm == rhs.upperTerm &&
        lhs.lowerTerm == rhs.lowerTerm
    }
}

// MARK: Result

extension Exercise {
    enum Result {
        case equal
        case notEqual
    }

    /// Parse the exercise and return the result.
    /// Return nil if one of the terms couldn't be parsed.
    var result: Result? {
        let upper = Term(string: upperTerm)
        let lower = Term(string: lowerTerm)

        guard let upperValue = upper.evaluate(verbose: true),
              let lowerValue = lower.evaluate(verbose: true) else { return nil }

        return upperValue == lowerValue ? .equal : .notEqual
    }
}
