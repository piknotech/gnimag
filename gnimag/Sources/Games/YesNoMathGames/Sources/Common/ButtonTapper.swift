//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Tapping

/// ButtonTapper uses the screen layout to tap on the relevant (equal/notEqual) buttons.
class ButtonTapper {
    private let underlyingTapper: AnywhereTapper

    /// The screen layout. Before using ButtonTapper, this must be set from outside.
    var screen: ScreenLayout!

    /// Default initializer.
    init(underlyingTapper: AnywhereTapper) {
        self.underlyingTapper = underlyingTapper
    }

    /// Tap on the correct button for a given exercise result.
    func performTap(for result: Exercise.Result) {
        switch result {
        case .equal:
            underlyingTapper.tap(atAbsolute: screen.equalButtonCenter, screenSize: screen.size)

        case .notEqual:
            underlyingTapper.tap(atAbsolute: screen.notEqualButtonCenter, screenSize: screen.size)
        }
    }
}
