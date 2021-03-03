//
//  Created by David Knothe on 05.01.21.
//  Copyright © 2019 - 2021 Piknotech. All rights reserved.
//

import Tapping

/// Use this for debugging or demonstration purposes.
struct MultiTapper: SomewhereTapper {
    let tappers: [SomewhereTapper]

    /// Default initializer.
    init(_ tappers: SomewhereTapper...) {
        self.tappers = tappers
    }

    func tap() {
        tappers.forEach { $0.tap() }
    }
}
