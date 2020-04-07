//
//  Created by David Knothe on 26.03.20.
//  Copyright © 2019 - 2020 Piknotech. All rights reserved.
//

import Foundation
import Geometry
import Tapping

/// ButtonTapper uses the screen layout to tap on the relevant (equal/notEqual) buttons.
class ButtonTapper {
    private let underlyingTapper: ArbitraryLocationTapper

    /// The screen layout. Before using ButtonTapper, this must be set from outside.
    var screen: ScreenLayout!

    /// Default initializer.
    init(underlyingTapper: ArbitraryLocationTapper) {
        self.underlyingTapper = underlyingTapper
    }

    /// Tap on the correct button for a given exercise result.
    func performTap(for result: Exercise.Result) {
        switch result {
        case .equal:
            let location = relativeTappingLocation(for: screen.equalButton)
            underlyingTapper.tap(at: location)

        case .notEqual:
            let location = relativeTappingLocation(for: screen.notEqualButton)
            underlyingTapper.tap(at: location)
        }
    }

    /// Get the relative tapping location (for ArbitraryLocationTapper) from a button.
    private func relativeTappingLocation(for button: Circle) -> CGPoint {
        let x = button.center.x / screen.size.width
        let y = button.center.y / screen.size.height
        return CGPoint(x: x, y: y)
    }
}
