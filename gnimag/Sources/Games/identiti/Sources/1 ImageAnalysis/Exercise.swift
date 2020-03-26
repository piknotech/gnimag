//
//  Created by David Knothe on 20.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation

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
